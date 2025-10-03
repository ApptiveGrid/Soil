Class {
	#name : #SoilGraphExporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'migrationMap',
		'metaSegment',
		'versionMap'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #'as yet unclassified' }
SoilGraphExporter >> export: aSoilObjectId [ 
	self processObjectId: aSoilObjectId.
	self processLoop 
]

{ #category : #initialization }
SoilGraphExporter >> initialize [ 
	super initialize.
	migrationMap := Dictionary new.
	versionMap := Dictionary new.
]

{ #category : #visiting }
SoilGraphExporter >> isUpToDateCluster: aCluster [
	
	"check if all behavior descriptions of the cluster are at the newest 
	version"
	^ aCluster behaviorDescriptions allSatisfy: [ :objectId | 
		objectId version = (versionMap at: objectId asSoilObjectId) ]
]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> metaSegment [ 
	^ metaSegment ifNil: [ 
		metaSegment := soil objectRepository metaSegment ].

]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> migrate: aClass to: aFullBlockClosure [ 
	migrationMap 
		at: (soil behaviorRegistry nameAt: aClass name ifAbsent: [self halt]) index 
		put: aFullBlockClosure 

]

{ #category : #actions }
SoilGraphExporter >> migrateCluster: cluster [ 
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
SoilGraphExporter >> stream [
	^ stream
]

{ #category : #accessing }
SoilGraphExporter >> stream: anObject [

	stream := anObject
]

{ #category : #accessing }
SoilGraphExporter >> transaction: aTransaction [ 
	transaction := aTransaction 
]

{ #category : #visiting }
SoilGraphExporter >> updateCluster: aCluster [
	"Behavior objectIds and versions depend on the time and state 
	of the software when they are being written the first time. 
	They become meaningless through export. The current assumption
	is that the export is a short-lived structure that is used 
	to be re-imported somewhere else. The common denominator here
	is the actual state of the software. We can match that if we
	make sure that the clusters are on the newest version "
	(self isUpToDateCluster: aCluster) ifTrue: [ ^ aCluster ].
	"if the cluster is not up-to-date we materialize the 
	object which will upgrade it"
	^ (aCluster 
		transaction: transaction;
		materializeObject;
		asNewClusterVersion)
			version: 0;
			yourself
			
]

{ #category : #visiting }
SoilGraphExporter >> visitPersistentClusterVersion: aCluster [ 
	| index cluster |
	"remove all information regarding the current segment as it
	will be invalid when exported"
	aCluster detachFromSegment.

	"write format objectId, behaviors, cluster, index settings"
	aCluster objectId writeOn: stream.

	cluster := self migrateCluster: aCluster.
	self writeBehaviorDescriptions: cluster behaviorDescriptions.
	cluster := self updateCluster: aCluster.
	"write the cleaned and up-to-date cluster"
	cluster serializeOn: stream .
	"for all indexes being used remember the index setting for it "
	cluster indexIds do: [ :indexId |
		index := soil objectRepository firstSegment indexManager at: indexId.
		stream 
			nextPutAll: (index keySize asByteArrayOfSize: 2);
			nextPutAll: ( index valueSize asByteArrayOfSize: 2 );
			nextPutAll: ( index maxLevel asByteArrayOfSize: 2 ) ].
	cluster references do: [ :reference |
		self processObjectId: reference ].

]

{ #category : #visiting }
SoilGraphExporter >> writeBehaviorDescriptions: aCollection [ 
	| unwritten record |
	"write only behaviors that have not been written already"
	unwritten := aCollection reject: [ :each | versionMap includesKey: each asSoilObjectId ].
	
	"write size"
	stream nextPutAll: (unwritten size asByteArrayOfSize: 8).
	unwritten do: [ :reference | 
		record := transaction materializeRecord: (self metaSegment at: reference index). 
		"remember the current maximum version of each behavior so we can 
		easily figure out which of the objects need to be migrated"
		versionMap 
			at: record objectId 
			put: record object version.
		record objectId writeOn: stream.
		record serializeOn: stream
	].
]
