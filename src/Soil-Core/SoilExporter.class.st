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
	"we have no good format for now so we just write the number of 
	descriptions we are gonna write followed by the descriptions"
	stream nextPutAll: ((metaSegment lastObjectIndex - 2) asByteArrayOfSize: 8).
	3 to: metaSegment lastObjectIndex do: [ :n | 
		record := transaction materializeRecord: (metaSegment at: n). 
		"remember the current maximum version of each behavior so we can 
		easily figure out which of the objects need to be migrated"
		maxVersions 
			at: record objectId 
			put: record object version.
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

{ #category : #visiting }
SoilExporter >> isUpToDateCluster: aCluster [
	
	"check if all behavior descriptions of the cluster are at the newest 
	version"
	^ aCluster behaviorDescriptions allSatisfy: [ :objectId | 
		objectId version = (maxVersions at: objectId asSoilObjectId) ]
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
	"remove all information regarding the current segment as it
	will be invalid when exported"
	aCluster detachFromSegment.
	cluster := (self isUpToDateCluster: aCluster)
		ifTrue: [ aCluster ] 
		ifFalse: [ 
			"if the cluster is not up-to-date we materialize the 
			object which will upgrade it"
			aCluster 
				transaction: transaction;
				materializeObject;
				asNewClusterVersion ].
	"write the cleaned and up-to-date cluster"
	self write: (self migrateCluster: cluster).
	cluster references do: [ :reference |
		self processObjectId: reference ].
	"for all indexes being used remember the index setting for it "
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
