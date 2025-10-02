Class {
	#name : #SoilImporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'lastIndex',
		'idMap',
		'newId'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #importing }
SoilImporter >> import [
	| objectId |
	lastIndex := Array new: 2.
	lastIndex at: 1 put: (transaction objectRepository metaSegment) lastObjectIndex.
	lastIndex at: 2 put: (transaction objectRepository segmentAt: 1) lastObjectIndex.
	self importBehaviors.
	[ stream atEnd ] whileFalse: [ 
		objectId := self newObjectIdFor: (SoilObjectId readFrom: stream).
		newId ifNil: [newId := objectId ].
		self processCluster: (SoilPersistentClusterVersion new readFrom: stream) objectId: objectId ].
	
	soil objectRepository firstSegment updateLastObjectIndex: (lastIndex at: 2)
]

{ #category : #importing }
SoilImporter >> importBehaviors [
	| size cluster objectId d segment max  presentObjectId |
	size := (stream next: 8) asInteger.
	d := OrderedCollection new.
	segment := soil objectRepository metaSegment.
	max := 0.
	1 to: size do: [ :n |
		objectId := SoilObjectId readFrom: stream.
		max := max max: objectId index.
		cluster := SoilPersistentClusterVersion new readFrom: stream .
		cluster version: 1.
		cluster previousVersionPosition: 0.
		cluster 
			transaction: transaction;
			materializeObject.
		presentObjectId := soil behaviorRegistry 
			nameAt: cluster object behaviorIdentifier 
			ifAbsent: [ nil ].
		presentObjectId 
			ifNotNil: [ :oid |
				(segment basicAt: presentObjectId index ifAbsent: [ nil ]) 
					ifNotNil: [ :presentBehavior | 
						presentBehavior 
							transaction: transaction;
							materializeObject.
						(presentBehavior object hasSameShape: cluster object )
							ifTrue: [ 
								idMap at: objectId put: (presentObjectId asObjectIdVersion: presentBehavior version).
								"if oid is the same and shape this is the wanted case" ]
							ifFalse: [ self halt ]  ]
						ifNil: [ self halt ] ] 
			ifNil: [ 
				cluster version: 1.
				segment at: (self newObjectIdFor: objectId version: 1) index putBytes: cluster serialize ] ].
	segment updateLastObjectIndex: max 
]

{ #category : #initialization }
SoilImporter >> initialize [ 
	super initialize.
	idMap := Dictionary new
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

{ #category : #'as yet unclassified' }
SoilImporter >> processCluster: cluster objectId: objectId [
	| keySize valueSize index |
	cluster 
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
