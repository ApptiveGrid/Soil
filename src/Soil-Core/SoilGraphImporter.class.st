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
		'legacyOids'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #importing }
SoilGraphImporter >> import [
	"set the last indexes of this database. Importing will not use the objectIds that
	have been exported. This might waste huge amounts of ids. So we remap all objectIds
	to ids that come right after the current ones."
	lastIndex := Array new: 2.
	lastIndex at: 1 put: (transaction objectRepository metaSegment) lastObjectIndex.
	lastIndex at: 2 put: (transaction objectRepository segmentAt: 1) lastObjectIndex.
	clusters := OrderedCollection new.
	"read the list of objejctIds to be imported. This gives us access to the objects that
	will have different objectids after import"
	legacyOids := Array new: stream next.
	1 to: legacyOids size do: [ :n |
		legacyOids at: n put: (SoilObjectId readFrom: stream) ].
	"read the list of non-mapped objectIds. Before importing we need to register a local 
	object for all of these objectids so they can be re-mapped."
	toBeReplaced := Array new: stream next.
	1 to: toBeReplaced size do: [ :n |
		toBeReplaced at: n put: (SoilObjectId readFrom: stream) ].
	"Now just read all clusters til the end and import them into the object repository"
	[ stream atEnd ] whileFalse: [ 
		clusters add: self readCluster ].
	
	soil objectRepository firstSegment updateLastObjectIndex: (lastIndex at: 2)
]

{ #category : #importing }
SoilGraphImporter >> importBehaviorCluster: cluster [

	"When importing a behavior we need to check if it is already present 
	in this database"
	| newOid |
	(self presentBehaviorWithName: cluster object behaviorIdentifier)
		ifNotNil: [ :presentOid |
			(self metaSegment basicAt: presentOid index ifAbsent: [ Error signal: 'the behavior is present by name but not as object on the heap' ]) 
				ifNotNil: [ :presentBehavior | 
					"We need to materialize the behavior in order to check our
					assumption that the imported behavior and the present have
					the same shape"
					presentBehavior 
						transaction: transaction;
						materializeObject.
					(presentBehavior object hasSameShape: cluster object )
						ifTrue: [ 
							"Behaviors have the same shape so we can adapt the objectId of the 
							present behavior and the version"
							idMap 
								at: cluster objectId 
								put: (presentOid asObjectIdVersion: presentBehavior object version) ]
						ifFalse: [ Error signal: 'there is a shape difference in behavior. Yet not covered case' ] ] ] 
		ifNil: [ 
			"The behavior is not in the database so we import the behavior with 
			version 1"
			cluster object version: 1.
			newOid := self newObjectIdFor: cluster objectId version: 1.
			self metaSegment 
				at: newOid index 
				putBytes: (cluster asNewClusterVersion version: 1; serialize) ] 
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
	replacements := OrderedCollection new
]

{ #category : #importing }
SoilGraphImporter >> metaSegment [ 
	^ metaSegment ifNil: [  
		metaSegment := soil objectRepository metaSegment ]

]

{ #category : #accessing }
SoilGraphImporter >> newId [
	^ newId
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
	| objectId cluster keySize valueSize index maxLevel originalOid serialized |
	originalOid := SoilObjectId readFrom: stream.
	objectId := self newObjectIdFor: originalOid.
	(stream next: 8) asInteger timesRepeat: [ 
		 self readBehaviorDescription ].
	cluster := (SoilPersistentClusterVersion new readFrom: stream)
		detachFromSegment;
		objectId: objectId;
		version: self databaseVersion.
	cluster references: (cluster references collect: [:id| 
		(toBeReplaced includes: id) 
			ifTrue: [ replacements at: (toBeReplaced indexOf: id) ] 
			ifFalse: [ self newObjectIdFor: id ] ]).
	cluster indexIds do: [ :indexId |
		keySize := (stream next: 2) asInteger.
		valueSize := (stream next: 2) asInteger.
		maxLevel := (stream next: 2) asInteger.
		index := soil objectRepository firstSegment indexManager createIndexWithId: indexId class: SoilSkipList.
		index keySize: keySize; valueSize: valueSize; maxLevel: maxLevel.
		(stream next: 8) asInteger timesRepeat: [
			index basicAt: (stream next: keySize) asInteger put: (self newObjectIdFor: (SoilObjectId readFrom: stream)) ].
		
		index writePages  ].
	cluster behaviorDescriptions: (cluster behaviorDescriptions collect: [ :bd |
		 idMap at: bd objectId asSoilObjectId ]).
	serialized := cluster serialize.
	soil objectRepository 
		at: cluster objectId 
		putBytes: serialized.
	^ cluster 
]

{ #category : #'as yet unclassified' }
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
