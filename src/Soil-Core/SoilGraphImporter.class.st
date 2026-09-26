Class {
	#name : #SoilGraphImporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'lastIndex',
		'idMap',
		'clusters',
		'toBeReplaced',
		'replacements',
		'legacyOids',
		'addedBehaviorNames',
		'acceptsExportsFromOlderVersions'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilGraphImporter >> acceptExportsFromOlderVersions [
	"Look an arriving shape up in the chain of its class before treating it as a new one,
	so that a stream written by an image with older code still finds the version it belongs
	to. Off by default, and switching it on means accepting an imprecision: shapes are
	compared field by field, so a shape that equals an older version is taken *for* that
	older version - and two versions look alike as soon as an instance variable is removed
	and put back.

	Without it the rule is plain and can be stated in one line: what arrives is the newest
	shape of its class, either the one the target already holds or the next version. A
	shape that is neither raises, rather than being filed under a version it happens to
	resemble."
	acceptsExportsFromOlderVersions := true
]

{ #category : #accessing }
SoilGraphImporter >> acceptsExportsFromOlderVersions [
	"false by default - see #acceptExportsFromOlderVersions for what saying it costs"
	^ acceptsExportsFromOlderVersions ifNil: [ false ]
]

{ #category : #importing }
SoilGraphImporter >> addNextVersionOf: cluster at: presentOid [
	^ self
		  useVersion: (soil behaviorRegistry
				   addNewVersion: cluster object
				   withId: presentOid
				   transaction: transaction)
		  for: cluster
		  at: presentOid
]

{ #category : #importing }
SoilGraphImporter >> bytesOf: cluster withIndexId: oldId replacedBy: newId [
	"The dictionary an index belongs to holds nothing but the id of its index - everything
	else is transient, see SoilIndexedDictionary class>>soilTransientInstVars - so its bytes
	are that id, written as a string. They are rewritten rather than the dictionary being
	materialized: materializing opens the index under the id the dictionary carries, which
	is the source's, and another database has no index under it.

	The id is replaced as the serializer writes it, length included, and a cluster's bytes
	hold no positions, so the new id may be longer or shorter. Found anywhere but exactly
	once, the bytes are not what this expects, and that is said instead of guessed at."
	| bytes old position |
	bytes := cluster bytes.
	old := self serializedString: oldId.
	position := bytes indexOfSubCollection: old startingAt: 1.
	(position = 0 or: [ (bytes indexOfSubCollection: old startingAt: position + 1) > 0 ])
		ifTrue: [
			SoilUnsupportedError signal:
				'the bytes of an object that owns an index were expected to carry its id exactly once' ].
	^ bytes
		copyReplaceFrom: position
		to: position + old size - 1
		with: (self serializedString: newId)
]

{ #category : #importing }
SoilGraphImporter >> import [
	"inside the commit semaphore, where every commit hands out its ids: from
	#memoizeSegmentIndexes to #updateSegmentIndexes the import counts on from the last
	index of each segment and writes there, and a commit in between would be given the
	same ids and have what it created overwritten. That the import holds up other
	writers meanwhile is what every commit does."
	soil critical: [
		[ self
			  readFormatVersion;
			  memoizeSegmentIndexes;
			  readObjectIdsBeingImported;
			  readObjectIdsToBeReplaced;
			  readClusters;
			  updateSegmentIndexes;
			  makeTheImportPartOfTheCommit ]
			on: Error
			do: [ :e |
				self undoBehaviorNamesAddedSoFar.
				e pass ] ]
]

{ #category : #importing }
SoilGraphImporter >> importBehaviorCluster: cluster [
	"A behavior that arrives either has a counterpart here or it does not, and if it does,
	its shape either matches that counterpart or it does not."
	self
		presentDescriptionFor: cluster
		ifPresent: [ :presentDescription :presentOid |
			(presentDescription matchesDescription: cluster object)
				ifTrue: [
					self
						useVersion: presentDescription version
						for: cluster
						at: presentOid ]
				ifFalse: [
					self
						importBehaviorOfDifferentShape: cluster
						knownAs: presentDescription
						at: presentOid ] ]
		ifAbsent: [ self importBehaviorNewToThisDatabase: cluster ]
]

{ #category : #importing }
SoilGraphImporter >> importBehaviorNewToThisDatabase: cluster [
	"a class this database has not stored before. The id is ours; the name the registry
	writes is what #undoBehaviorNamesAddedSoFar takes back if anything later fails."
	soil behaviorRegistry
		addNewDescription: cluster object
		withId: (self newObjectIdFor: cluster objectId version: 1)
		transaction: transaction.
	addedBehaviorNames add: cluster object behaviorIdentifier
]

{ #category : #importing }
SoilGraphImporter >> importBehaviorOfDifferentShape: cluster knownAs: presentDescription at: presentOid [
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

	The first reading is the one that has to be asked for: #acceptExportsFromOlderVersions
	turns the chain lookup on and with it the imprecision that a shape equal to an older
	version is taken for that version. Off, only the second applies - and the third then
	catches everything that is not the shape of the live class, instead of it being filed
	under a version it happens to resemble."
	self acceptsExportsFromOlderVersions ifTrue: [
		(self versionKnownInChainFor: cluster at: presentOid) ifNotNil: [ :knownVersion |
			^ self useVersion: knownVersion for: cluster at: presentOid ] ].
	self shapeOfTheLiveClassIn: cluster ifFalse: [
		^ self signalShapeConflictFor: cluster against: presentDescription ].
	^ self addNextVersionOf: cluster at: presentOid
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
	replacements := Dictionary new.
	addedBehaviorNames := OrderedCollection new.
	acceptsExportsFromOlderVersions := false
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
SoilGraphImporter >> memoizeSegmentIndexes [
	"where each segment has handed out ids up to. #newObjectIdFor: counts on from here,
	because the ids in the stream are positions in the source's segments and are taken
	here - so every imported object is remapped to one after the last in use. Wasteful in
	id space; the alternative would be a lookup per id. #updateSegmentIndexes writes the
	counted-up values back at the end."
	lastIndex := Array new: 2.
	lastIndex at: 1 put: transaction objectRepository metaSegment lastObjectIndex.
	lastIndex at: 2 put: (transaction objectRepository segmentAt: 1) lastObjectIndex
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
SoilGraphImporter >> pointAtLocalBehaviorDescriptions: cluster [
	"the descriptions were mapped to this database's own while they were read - see
	#importBehaviorCluster:"
	cluster behaviorDescriptions: (cluster behaviorDescriptions collect: [ :each |
		 idMap at: each objectId asSoilObjectId ])
]

{ #category : #importing }
SoilGraphImporter >> presentBehaviorWithName: aSymbol [
	^ soil behaviorRegistry 
		nameAt: aSymbol
		ifAbsent: [ nil ].
]

{ #category : #importing }
SoilGraphImporter >> presentDescriptionFor: cluster ifPresent: presentBlock ifAbsent: absentBlock [
	| presentOid |
	presentOid := self presentBehaviorWithName: cluster object behaviorIdentifier.
	presentOid ifNil: [ ^ absentBlock value ].
	^ presentBlock
		  value: ((transaction objectWithId: presentOid) ifNil: [
				   Error signal:
						   'the behavior is present by name but not as object on the heap' ])
		  value: presentOid
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
	behaviors come first because the cluster refers to them.

	The version stamped here is the importing transaction's, not the database's. A record
	is readable by a transaction whose readVersion is at least the record's version, and
	an imported object has no older version to fall back to - so stamping it with the
	database's current version made the import invisible to the very transaction that ran
	it, as soon as anything else had committed since that transaction started. Which, in a
	database that is being used, is most of the time."
	| objectId |
	objectId := self newObjectIdFor: (SoilObjectId readFrom: stream).
	(stream next: 8) asInteger timesRepeat: [ self readBehaviorDescription ].
	^ (SoilPersistentClusterVersion new readFrom: stream)
		  detachFromSegment;
		  objectId: objectId;
		  version: transaction readVersion;
		  yourself
]

{ #category : #importing }
SoilGraphImporter >> readClusters [
	clusters := OrderedCollection new.
	[ stream atEnd ] whileFalse: [ clusters add: self readCluster ]
]

{ #category : #importing }
SoilGraphImporter >> readFormatVersion [
	"the first thing in the stream, and the only thing that can be read from a stream
	whose format is unknown. Refusing here is the point: everything after this is read by
	position, so a stream from another version would not fail, it would be misread."
	| version |
	version := (stream next: 2) asInteger.
	version = SoilGraphExporter formatVersion ifFalse: [
		SoilIncompatibleExportFormat new
			importerUnderstands: SoilGraphExporter formatVersion;
			streamSays: version;
			signal ]
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
			add: (self newObjectIdFor: (SoilObjectId readFrom: stream)) ].
	index writePages
]

{ #category : #importing }
SoilGraphImporter >> readIndexesOf: cluster [
	"every index gets an id of its own here, as every object gets an object id of its own.
	The id it arrives with names the index file in the source, and in the database the
	export came from - a copy of a space inside one user - creating the index under that
	id put the copy's index where the source's was, and both read the same entries from
	then on. The id is in two places, the cluster's list of its indexes and the dictionary
	the index belongs to, and both are changed."
	cluster indexIds: (cluster indexIds collect: [ :indexId | | newId |
		newId := SoilIndexedDictionary newIndexId.
		self readIndexOfCluster: cluster withId: newId.
		cluster bytes: (self bytesOf: cluster withIndexId: indexId replacedBy: newId).
		newId ])
]

{ #category : #importing }
SoilGraphImporter >> readName [
	^ (stream next: stream next) asString asSymbol
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
	one. References to them are re-pointed at the object #replaceObject:as: registered
	under the same name. Reading the names is also where a missing registration is found,
	before anything has been written."
	| name |
	toBeReplaced := Dictionary new.
	stream next timesRepeat: [
		name := self readName.
		self replacementNamed: name.
		toBeReplaced at: (SoilObjectId readFrom: stream) put: name ]
]

{ #category : #importing }
SoilGraphImporter >> remapReferencesOf: cluster [
	"a reference either points at something this import brings along - then it gets that
	object's new id - or at something the export left out, and then it points at what the
	caller registered for it through #replaceObject:"
	cluster references: (cluster references collect: [ :id |
		 toBeReplaced
			 at: id
			 ifPresent: [ :name | self replacementNamed: name ]
			 ifAbsent: [ self newObjectIdFor: id ] ])
]

{ #category : #actions }
SoilGraphImporter >> replaceObject: anObject as: aName [
	"the object this database puts in place of the one the export left out under that name.
	See SoilGraphExporter>>replaceObject:as: for why it is a name and not a position."
	replacements at: aName put: (transaction objectIdOf: anObject)
]

{ #category : #accessing }
SoilGraphImporter >> replacementNamed: aName [
	^ replacements
		at: aName
		ifAbsent: [
			SoilInvalidReplacement signal:
				'the export leaves out an object to be replaced as ' , aName printString
				, ', and nothing is registered under that name' ]
]

{ #category : #private }
SoilGraphImporter >> serializedString: aString [
	^ ByteArray streamContents: [ :bytes |
		SoilSerializer new
			stream: bytes;
			nextPutString: aString ]
]

{ #category : #importing }
SoilGraphImporter >> shapeOfTheLiveClassIn: cluster ifFalse: aBlock [
	^ (cluster object matchesDescription:
		   (SoilBehaviorDescription for: cluster object objectClass))
		  ifFalse: aBlock
]

{ #category : #importing }
SoilGraphImporter >> signalShapeConflictFor: cluster against: presentDescription [
	^ SoilBehaviorShapeConflict new
		  behaviorIdentifier: cluster object behaviorIdentifier;
		  importedInstVarNames: cluster object instVarNames;
		  presentInstVarNames: presentDescription instVarNames;
		  signal
]

{ #category : #importing }
SoilGraphImporter >> store: cluster [
	soil objectRepository at: cluster objectId putBytes: cluster serialize
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
SoilGraphImporter >> updateSegmentIndexes [
	"the counterpart of #memoizeSegmentIndexes, and it runs only once every cluster is
	written. Until then a failure leaves the bytes written so far orphaned: no segment
	says those ids are taken, so the next allocation simply writes over them."
	soil objectRepository metaSegment updateLastObjectIndex: (lastIndex at: 1).
	soil objectRepository firstSegment updateLastObjectIndex: (lastIndex at: 2)
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
