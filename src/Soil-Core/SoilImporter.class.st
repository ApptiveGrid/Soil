Class {
	#name : #SoilImporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'lastIndex',
		'idMap',
		'newId',
		'metaSegment'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #importing }
SoilImporter >> import [
	lastIndex := Array new: 2.
	lastIndex at: 1 put: (transaction objectRepository metaSegment) lastObjectIndex.
	lastIndex at: 2 put: (transaction objectRepository segmentAt: 1) lastObjectIndex.

	[ stream atEnd ] whileFalse: [ 
		self readCluster ].
	
	soil objectRepository firstSegment updateLastObjectIndex: (lastIndex at: 2)
]

{ #category : #importing }
SoilImporter >> importBehaviorCluster: cluster [

	"When importing a behavior we need to check if it is already present 
	in this database"
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
			cluster version: 1.
			self metaSegment 
				at: (self newObjectIdFor: cluster objectId version: 1) index 
				putBytes: cluster serialize ] 
]

{ #category : #initialization }
SoilImporter >> initialize [ 
	super initialize.
	idMap := Dictionary new
]

{ #category : #importing }
SoilImporter >> metaSegment [ 
	^ metaSegment ifNil: [  
		metaSegment := soil objectRepository metaSegment ]

]

{ #category : #accessing }
SoilImporter >> newId [
	^ newId
]

{ #category : #'instance creation' }
SoilImporter >> newObjectIdFor: aSoilObjectId [ 
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
SoilImporter >> newObjectIdFor: aSoilObjectId version: anInteger [ 
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
SoilImporter >> presentBehaviorWithName: aSymbol [
	^ soil behaviorRegistry 
		nameAt: aSymbol
		ifAbsent: [ nil ].
]

{ #category : #importing }
SoilImporter >> readBehaviorDescription [
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
SoilImporter >> readCluster [
	| objectId cluster keySize valueSize index |
	objectId := self newObjectIdFor: (SoilObjectId readFrom: stream).
	newId ifNil: [newId := objectId ].
	(stream next: 8) asInteger timesRepeat: [ 
		 self readBehaviorDescription ].
	cluster := (SoilPersistentClusterVersion new readFrom: stream)
		detachFromSegment;
		objectId: objectId;
		version: self databaseVersion.
	cluster references: (cluster references collect: [:id| self newObjectIdFor: id]).
	cluster indexIds do: [ :indexId |
		keySize := (stream next: 2) asInteger.
		valueSize := (stream next: 2) asInteger.
		index := soil objectRepository firstSegment indexManager createIndexWithId: indexId class: SoilSkipList.
		index keySize: keySize; valueSize: valueSize; maxLevel: (stream next: 2) asInteger .
		index writePages  ].
	cluster behaviorDescriptions: (cluster behaviorDescriptions collect: [ :bd |
		 idMap at: bd objectId asSoilObjectId ]).
	soil objectRepository 
		at: cluster objectId 
		putBytes: cluster serialize 
]

{ #category : #accessing }
SoilImporter >> stream: aReadStream [ 
	stream := aReadStream 
]

{ #category : #accessing }
SoilImporter >> transaction: anAGBaseTransaction [ 
	transaction := anAGBaseTransaction 
]
