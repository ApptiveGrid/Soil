Class {
	#name : #SoilExporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'migrationMap',
		'maxVersions'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #'as yet unclassified' }
SoilExporter >> export: aSoilObjectId [ 
	self exportBehaviorRegistry.
	self processObjectId: aSoilObjectId.
	self processLoop 
]

{ #category : #'as yet unclassified' }
SoilExporter >> exportBehaviorRegistry [
	| metaSegment record |
	metaSegment := soil objectRepository metaSegment.
	stream nextPutAll: ((metaSegment lastObjectIndex - 2) asByteArrayOfSize: 8).
		3 to: metaSegment lastObjectIndex do: [ :n | 
			record := transaction materializeRecord: (metaSegment at: n). 
			record object isCurrent ifFalse: [ self halt ].
			maxVersions at: record objectId put: record object version.
			record objectId writeOn: stream.
			record serializeOn: stream
		].
]

{ #category : #initialization }
SoilExporter >> initialize [ 
	super initialize.
	migrationMap := Dictionary new.
	maxVersions := Dictionary new.
]

{ #category : #'as yet unclassified' }
SoilExporter >> migrate: aClass to: aFullBlockClosure [ 
	migrationMap 
		at: (soil behaviorRegistry nameAt: aClass name ifAbsent: [self halt]) index 
		put: aFullBlockClosure 

]

{ #category : #actions }
SoilExporter >> migrateCluster: cluster [ 
	| block |
	cluster behaviorDescriptions ifEmpty: [ ^ cluster ].
	block := migrationMap
		at: cluster behaviorDescriptions first index
		ifAbsent: [ nil ].
	block ifNotNil: [ 
		^ block value: cluster ].
	^ cluster
	
]

{ #category : #accessing }
SoilExporter >> stream [
	^ stream 
]

{ #category : #accessing }
SoilExporter >> stream: anObject [

	stream := anObject
]

{ #category : #accessing }
SoilExporter >> transaction: aTransaction [ 
	transaction := aTransaction 
]

{ #category : #visiting }
SoilExporter >> visitPersistentClusterVersion: aCluster [ 
	| index cluster |
	cluster := (aCluster behaviorDescriptions allSatisfy: [ :ref | 
		(ref version = (maxVersions at: ref asSoilObjectId)) ])
		ifTrue: [ 
				aCluster 
					detachFromSegment;
					yourself ] 
		ifFalse: [ 
			(aCluster 
				transaction: transaction;
				materializeObject;
				asNewClusterVersion) detachFromSegment; yourself ].
	self write: (self migrateCluster: cluster).
	cluster references do: [ :reference |
		self processObjectId: reference ].
	cluster indexIds do: [ :indexId |
		index := (soil objectRepository segmentAt: 1) indexManager at: indexId ifAbsent: [ self halt ].
		stream 
			nextPutAll: (index keySize asByteArrayOfSize: 2);
			nextPutAll: ( index valueSize asByteArrayOfSize: 2 );
			nextPutAll: ( index maxLevel asByteArrayOfSize: 2 ) ]
]

{ #category : #writing }
SoilExporter >> write: cluster [ 
	cluster objectId writeOn: stream.
	cluster serializeOn: self stream 
]
