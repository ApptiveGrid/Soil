Class {
	#name : #SoilGraphImporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'lastIndex',
		'idMap',
		'metaSegment',
		'clusters',
		'toBeReplaced',
		'replacements',
		'legacyOids',
		'addedBehaviorNames',
		'assumesImportedShapesAreNewest'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilGraphImporter >> assumeImportedShapesAreNewest [
	"Take every shape that arrives for the newest one this class has, and append it as the
	next version without looking at the chain. Say this when the stream cannot be older
	than the target - two images of one deployment, or an export taken moments ago.

	It is the cheaper reading and the more definite one: no shape is looked up, so no shape
	can be mistaken for an older one it happens to equal. What it gives up is the ability
	to take an export that *is* older: such a stream is then appended as if it were new,
	which grows the chain by a version that is in truth behind the one before it."
	assumesImportedShapesAreNewest := true
]

{ #category : #accessing }
SoilGraphImporter >> assumesImportedShapesAreNewest [
	"false by default: an arriving shape is looked up in the chain first, so an export
	older than the target still finds its version. See #assumeImportedShapesAreNewest for
	the other reading and what each costs."
	^ assumesImportedShapesAreNewest ifNil: [ false ]
]

{ #category : #importing }
SoilGraphImporter >> import [
	[ self
		  startAfterTheObjectIdsAlreadyInUse;
		  readObjectIdsBeingImported;
		  readObjectIdsToBeReplaced;
		  readClusters;
		  claimTheObjectIdsHandedOut;
		  makeTheImportPartOfTheCommit ]
		on: Error
		do: [ :e |
			self undoBehaviorNamesAddedSoFar.
			e pass ]
]

{ #category : #importing }
SoilGraphImporter >> claimTheObjectIdsHandedOut [
	"Only now, once every cluster is written. Until here a failure leaves the bytes
	written so far orphaned, and the next allocation simply overwrites them."
	soil objectRepository metaSegment updateLastObjectIndex: (lastIndex at: 1).
	soil objectRepository firstSegment updateLastObjectIndex: (lastIndex at: 2)
]

{ #category : #importing }
SoilGraphImporter >> makeTheImportPartOfTheCommit [
	"#readCluster and #importBehaviorCluster: write behavior descriptions and object data
	straight to the segments, past the transaction's normal tracking: with the default
	SoilAutomaticTrackingStrategy, markDirty: is a no-op and changes are noticed through a
	live fingerprint comparison in objectMap, and direct writing touches neither. So unless
	the caller happens to make some unrelated, genuine change in the same transaction,
	needsCommit stays false, SoilTransactionManager>>commitTransaction: never checkpoints,
	and everything written here - the behaviorRegistry's skip list index included - is
	silently never flushed. It looks committed and works for the rest of the session, and
	the import is gone the moment the database is closed and reopened.

	Flagging the transaction is the cheap way: routing the imported objects through the
	normal commitStrategy/objectMap path would re-serialize every one of them on commit,
	which is the per-object cost this bulk import exists to avoid. Checkpointing here
	directly is not an option either - this runs before the caller's own commit and would
	corrupt its journal and position bookkeeping. The flag only makes the existing,
	correctly ordered post-commit checkpoint fire."
	transaction markNeedsCheckpoint
]

{ #category : #importing }
SoilGraphImporter >> readClusters [
	clusters := OrderedCollection new.
	[ stream atEnd ] whileFalse: [ clusters add: self readCluster ]
]

{ #category : #importing }
SoilGraphImporter >> readObjectIdsBeingImported [
	"the objects this stream carries, under the ids they had in the source. They get
	different ones here, and #importedOids translates back through them."
	legacyOids := Array new: stream next.
	1 to: legacyOids size do: [ :n |
		legacyOids at: n put: (SoilObjectId readFrom: stream) ]
]

{ #category : #importing }
SoilGraphImporter >> readObjectIdsToBeReplaced [
	"objects the export left out because they exist here already - the receiving user, for
	one. References to them are re-pointed at what #replaceObject: registered."
	toBeReplaced := Array new: stream next.
	1 to: toBeReplaced size do: [ :n |
		toBeReplaced at: n put: (SoilObjectId readFrom: stream) ]
]

{ #category : #importing }
SoilGraphImporter >> startAfterTheObjectIdsAlreadyInUse [
	"The exported ids mean nothing here, so every one of them is remapped to an id after
	the ones this database has handed out. Wasteful in id space, and the alternative would
	be to look up each one."
	lastIndex := Array new: 2.
	lastIndex at: 1 put: transaction objectRepository metaSegment lastObjectIndex.
	lastIndex at: 2 put: (transaction objectRepository segmentAt: 1) lastObjectIndex
]

{ #category : #importing }
SoilGraphImporter >> undoBehaviorNamesAddedSoFar [
	"Everything else this import wrote is orphaned by the failure and will be overwritten:
	object data and behavior descriptions go straight to the segments, and the id counters
	are only advanced once all of it succeeded. Behavior *names* are the exception - they
	are looked up by class name, independently of any object reference, so one left behind
	would keep pointing at a slot that a later, unrelated class then reuses, aliasing two
	classes onto one behavior index."
	addedBehaviorNames do: [ :name |
		soil behaviorRegistry removeNameAt: name ifAbsent: [  ] ]
]


{ #category : #importing }
SoilGraphImporter >> importBehaviorCluster: cluster [
	"A behavior that arrives either has a counterpart here or it does not, and if it does,
	its shape either matches that counterpart or it does not."
	self
		presentBehaviorFor: cluster
		ifPresent: [ :presentBehavior :presentOid |
			(presentBehavior object matchesDescription: cluster object)
				ifTrue: [
					self
						useVersion: presentBehavior object version
						for: cluster
						at: presentOid ]
				ifFalse: [
					self
						importBehaviorOfDifferentShape: cluster
						knownAs: presentBehavior
						at: presentOid ] ]
		ifAbsent: [ self importBehaviorNewToThisDatabase: cluster ]
]

{ #category : #importing }
SoilGraphImporter >> importBehaviorNewToThisDatabase: cluster [
	"nothing to reconcile: it becomes version 1 and the name is registered. #import undoes
	that registration if anything later in the same import fails."
	| newOid |
	cluster object version: 1.
	newOid := self newObjectIdFor: cluster objectId version: 1.
	self metaSegment
		at: newOid index
		putBytes: (cluster asNewClusterVersion
				 version: 1;
				 serialize).
	soil behaviorRegistry nameAt: cluster object behaviorIdentifier put: newOid.
	addedBehaviorNames add: cluster object behaviorIdentifier
]

{ #category : #importing }
SoilGraphImporter >> importBehaviorOfDifferentShape: cluster knownAs: presentBehavior at: presentOid [
	"The target's current shape for this class is not the one being imported. Two of the
	three ways that happens are ordinary and both end in a description this database can
	read, so neither is a conflict:

	1. The target knows the imported shape as an older version of the chain. Then the
	   objects being imported carry a shape this database can migrate from, and pointing
	   them at that version is all that is needed - materializing them later runs the
	   usual shape adaptation.
	2. The imported shape is the one the class has in this image, and the target simply
	   has not written an object of that class since it changed. That is the next version
	   of the chain, and it is appended here exactly as an ordinary commit would have
	   appended it.

	What is left over is a shape that is neither in the chain nor the live class, which
	means the exporting image runs different code than this one - #updateCluster: raises
	the source to *its* current state, and that is then not ours. That one raises.

	A caller who knows that nothing older can arrive says so with
	#assumeImportedShapesAreNewest, and then only the second reading applies."
	self assumesImportedShapesAreNewest ifTrue: [
		^ self appendAsNextVersion: cluster after: presentBehavior at: presentOid ].
	(self versionKnownInChainFor: cluster at: presentOid) ifNotNil: [ :knownVersion |
		^ self useVersion: knownVersion for: cluster at: presentOid ].
	self shapeOfTheLiveClassIn: cluster ifFalse: [
		^ self signalShapeConflictFor: cluster against: presentBehavior ].
	^ self appendAsNextVersion: cluster after: presentBehavior at: presentOid
]

{ #category : #importing }
SoilGraphImporter >> appendAsNextVersion: cluster after: presentBehavior at: presentOid [
	"written where an ordinary commit would have written it: same slot, one version on"
	| newVersion |
	newVersion := presentBehavior object version + 1.
	self metaSegment
		at: presentOid index
		putBytes: (presentBehavior asNewClusterVersion
				 object: (cluster object
						  version: newVersion;
						  yourself);
				 version: newVersion;
				 transaction: transaction;
				 serializeObject;
				 serialize).
	soil behaviorRegistry
		appendCommittedVersion: cluster object
		forIndex: presentOid index.
	^ self useVersion: newVersion for: cluster at: presentOid
]

{ #category : #importing }
SoilGraphImporter >> presentBehaviorFor: cluster ifPresent: presentBlock ifAbsent: absentBlock [
	| presentOid |
	presentOid := self presentBehaviorWithName: cluster object behaviorIdentifier.
	presentOid ifNil: [ ^ absentBlock value ].
	^ presentBlock
		  value: ((self metaSegment
				    basicAt: presentOid index
				    ifAbsent: [
					    Error signal:
							    'the behavior is present by name but not as object on the heap' ])
				   transaction: transaction;
				   materializeObject;
				   yourself)
		  value: presentOid
]

{ #category : #importing }
SoilGraphImporter >> shapeOfTheLiveClassIn: cluster ifFalse: aBlock [
	^ (cluster object matchesDescription:
		   (SoilBehaviorDescription for: cluster object objectClass))
		  ifFalse: aBlock
]

{ #category : #importing }
SoilGraphImporter >> signalShapeConflictFor: cluster against: presentBehavior [
	^ SoilBehaviorShapeConflict new
		  behaviorIdentifier: cluster object behaviorIdentifier;
		  importedInstVarNames: cluster object instVarNames;
		  presentInstVarNames: presentBehavior object instVarNames;
		  signal
]

{ #category : #importing }
SoilGraphImporter >> useVersion: anInteger for: cluster at: presentOid [
	"the imported objects are pointed at a description this database already holds"
	^ idMap
		  at: cluster objectId
		  put: (presentOid asObjectIdVersion: anInteger)
]

{ #category : #importing }
SoilGraphImporter >> versionKnownInChainFor: cluster at: presentOid [
	^ soil behaviorRegistry
		  versionOfBehaviorWithIndex: presentOid index
		  matching: cluster object
		  transaction: transaction
]

{ #category : #'instance creation' }
SoilGraphImporter >> importedObjects [
	^ self importedOids collect: [ :each | transaction objectWithId: each ]
]

{ #category : #'instance creation' }
SoilGraphImporter >> importedOids [
	^ legacyOids collect: [ :each | self newObjectIdFor: each ]
]

{ #category : #initialization }
SoilGraphImporter >> initialize [
	super initialize.
	idMap := Dictionary new.
	replacements := OrderedCollection new.
	addedBehaviorNames := OrderedCollection new.
	assumesImportedShapesAreNewest := false
]

{ #category : #importing }
SoilGraphImporter >> metaSegment [ 
	^ metaSegment ifNil: [  
		metaSegment := soil objectRepository metaSegment ]

]

{ #category : #'instance creation' }
SoilGraphImporter >> newObjectIdFor: aSoilObjectId [ 
	| current |
	^ idMap
		at: aSoilObjectId
		ifAbsentPut: [ 
			current := lastIndex at: (aSoilObjectId segment + 1).
			SoilObjectId
				segment: aSoilObjectId segment 
				index: (lastIndex at: (aSoilObjectId segment + 1) put: current + 1)  ]
]

{ #category : #'instance creation' }
SoilGraphImporter >> newObjectIdFor: aSoilObjectId version: anInteger [ 
	| current |
	^ idMap
		at: aSoilObjectId
		ifAbsentPut: [ 
			current := lastIndex at: (aSoilObjectId segment + 1).
			SoilVersionedObjectId new
				segment: aSoilObjectId segment;
				index: (lastIndex at: (aSoilObjectId segment + 1) put: current + 1);
				version: anInteger  ]
]

{ #category : #importing }
SoilGraphImporter >> presentBehaviorWithName: aSymbol [
	^ soil behaviorRegistry 
		nameAt: aSymbol
		ifAbsent: [ nil ].
]

{ #category : #importing }
SoilGraphImporter >> readBehaviorDescription [
	| importOid  cluster |
	importOid := SoilObjectId readFrom: stream.
	
	cluster := (SoilPersistentClusterVersion new readFrom: stream)
		detachFromSegment;
		transaction: transaction;
		objectId: importOid;
		materializeObject;
		yourself .
	
	self importBehaviorCluster: cluster
]

{ #category : #importing }
SoilGraphImporter >> readCluster [
	| cluster |
	cluster := self readClusterHeader.
	self
		remapReferencesOf: cluster;
		readIndexesOf: cluster;
		pointAtLocalBehaviorDescriptions: cluster;
		store: cluster.
	^ cluster
]

{ #category : #importing }
SoilGraphImporter >> readClusterHeader [
	"the object's id in the source, the behaviors it needs, and the cluster itself. The
	behaviors come first because the cluster refers to them."
	| objectId |
	objectId := self newObjectIdFor: (SoilObjectId readFrom: stream).
	(stream next: 8) asInteger timesRepeat: [ self readBehaviorDescription ].
	^ (SoilPersistentClusterVersion new readFrom: stream)
		  detachFromSegment;
		  objectId: objectId;
		  version: self databaseVersion;
		  yourself
]

{ #category : #importing }
SoilGraphImporter >> readIndexOfCluster: cluster withId: indexId [
	"An index arrives as its three sizes and then its entries; a skipped one arrives with
	the sizes and no entries, so the structure of a grid survives without its rows. The
	values are object ids and are remapped like every other reference."
	| keySize valueSize maxLevel index |
	keySize := (stream next: 2) asInteger.
	valueSize := (stream next: 2) asInteger.
	maxLevel := (stream next: 2) asInteger.
	index := soil objectRepository firstSegment indexManager
		         createIndexWithId: indexId
		         class: SoilSkipList.
	index
		keySize: keySize;
		valueSize: valueSize;
		maxLevel: maxLevel.
	(stream next: 8) asInteger timesRepeat: [
		index
			basicAt: (stream next: keySize) asInteger
			put: (self newObjectIdFor: (SoilObjectId readFrom: stream)) ].
	index writePages
]

{ #category : #importing }
SoilGraphImporter >> readIndexesOf: cluster [
	cluster indexIds do: [ :indexId |
		self readIndexOfCluster: cluster withId: indexId ]
]

{ #category : #importing }
SoilGraphImporter >> pointAtLocalBehaviorDescriptions: cluster [
	"the descriptions were mapped to this database's own while they were read - see
	#importBehaviorCluster:"
	cluster behaviorDescriptions: (cluster behaviorDescriptions collect: [ :each |
		 idMap at: each objectId asSoilObjectId ])
]

{ #category : #importing }
SoilGraphImporter >> remapReferencesOf: cluster [
	"a reference either points at something this import brings along - then it gets that
	object's new id - or at something the export left out, and then it points at what the
	caller registered for it through #replaceObject:"
	cluster references: (cluster references collect: [ :id |
		 (toBeReplaced includes: id)
			 ifTrue: [ replacements at: (toBeReplaced indexOf: id) ]
			 ifFalse: [ self newObjectIdFor: id ] ])
]

{ #category : #importing }
SoilGraphImporter >> store: cluster [
	soil objectRepository at: cluster objectId putBytes: cluster serialize
]


{ #category : #actions }
SoilGraphImporter >> replaceObject: anAGUser [ 
	replacements add: (transaction objectIdOf: anAGUser)
]

{ #category : #accessing }
SoilGraphImporter >> stream: aReadStream [ 
	stream := aReadStream 
]

{ #category : #accessing }
SoilGraphImporter >> transaction: anAGBaseTransaction [ 
	transaction := anAGBaseTransaction.
	soil := anAGBaseTransaction soil 
]
