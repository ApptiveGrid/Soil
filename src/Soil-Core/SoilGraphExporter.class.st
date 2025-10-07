Class {
	#name : #SoilGraphExporter,
	#superclass : #SoilVisitor,
	#instVars : [
		'stream',
		'transaction',
		'migrationMap',
		'metaSegment',
		'versionMap',
		'indexesToSkip',
		'behaviors'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #visiting }
SoilGraphExporter >> behaviorAt: index [ 
	^ behaviors 
		at: index 
		ifAbsentPut: [ 
			 transaction materializeRecord: (self metaSegment at: index) ]

]

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
	indexesToSkip := OrderedCollection new.
	behaviors := Dictionary new.
]

{ #category : #visiting }
SoilGraphExporter >> isUpToDateCluster: aCluster [
	
	"check if all behavior descriptions of the cluster are at the newest 
	version"
	^ aCluster behaviorDescriptions allSatisfy: [ :objectId | 
		objectId version = (versionMap at: objectId asSoilObjectId ifAbsent: false ) ]
]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> metaSegment [ 
	^ metaSegment ifNil: [ 
		metaSegment := soil objectRepository metaSegment ].

]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> migrate: aClass to: aFullBlockClosure [ 
	migrationMap 
		at: (soil behaviorRegistry 
			nameAt: aClass name 
			ifAbsent: [Error signal: 'no class found']) index 
		put: aFullBlockClosure 

]

{ #category : #actions }
SoilGraphExporter >> migrateCluster: cluster [ 
	| block newCluster |
	cluster behaviorDescriptions ifEmpty: [ ^ cluster ].
	block := migrationMap
		at: cluster behaviorDescriptions first index
		ifAbsent: [ ^ cluster ].
	
	newCluster := cluster asNewClusterVersion.
	newCluster object: (block value: cluster).
	newCluster version: 1.
	newCluster 
		transaction: transaction;
		serializeObject.
	^ newCluster
]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> skipIndexes: aCollection [ 
	indexesToSkip := aCollection collect: [ :each |
		(each class = SoilObjectId)
			ifTrue: [ each ]
			ifFalse: [ transaction objectIdOf: each  ] ]
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
	| cluster |
	(self isUpToDateCluster: aCluster) ifTrue: [ ^ aCluster ].
	"if the cluster is not up-to-date we materialize the 
	object which will upgrade it"
	cluster := (aCluster 
		transaction: transaction;
		materializeObject;
		asNewClusterVersion)
			version: 1;
			yourself.
	transaction registerRecord: cluster.
	^ cluster
			
]

{ #category : #visiting }
SoilGraphExporter >> visitPersistentClusterVersion: aCluster [ 
	| cluster |
	"remove all information regarding the current segment as it
	will be invalid when exported"
	aCluster detachFromSegment.

	"write format objectId, behaviors, cluster, index settings"
	aCluster objectId writeOn: stream.
	 
	"cluster := self updateCluster: aCluster."
	cluster := self migrateCluster: aCluster.
	self writeBehaviorDescriptions: (cluster behaviorDescriptions collect: [:each | 
		(each isKindOf: SoilVersionedObjectId)
			ifTrue: [ self behaviorAt: each index ]
			ifFalse: [ self behaviorAt: each objectId index ] ]).
	"write the cleaned and up-to-date cluster"
	cluster 
		transaction: transaction;
		serializeOn: stream .
	"for all indexes being used remember the index setting for it "
	cluster indexIds ifNotEmpty: [ 
		cluster object ifNil: [  
			transaction registerRecord: (cluster 
				transaction: transaction;
				materializeObject;
				yourself) ].
		self visit: cluster object ].
	cluster references do: [ :reference |
		self processObjectId: reference ].
	stream nextPut: 255.

]

{ #category : #visiting }
SoilGraphExporter >> visitSkipListDictionary: aSkipListDictionary [ 
	| index count |
	index := aSkipListDictionary index wrapped.
	stream 
			nextPutAll: (index keySize asByteArrayOfSize: 2);
			nextPutAll: ( index valueSize asByteArrayOfSize: 2 );
			nextPutAll: ( index maxLevel asByteArrayOfSize: 2 ).
	(indexesToSkip includes: (transaction objectIdOf: aSkipListDictionary))
		ifTrue: [ 
			stream nextPutAll: (0 asByteArrayOfSize: 8) ]
		ifFalse: [ 
			count := 0.
			stream nextPutAll: (index size asByteArrayOfSize: 8).
			index newIterator associationsDo: [ :assoc |
				count := count + 1.
				self processObjectId: (SoilObjectId readFrom: assoc value readStream).
				stream 
					nextPutAll: (assoc key asByteArrayOfSize: index keySize);
					nextPutAll: (assoc value asByteArrayOfSize: index valueSize ) ] ].
		(count isNil or: [ index size = count ]) ifFalse: [ self halt ].
]

{ #category : #visiting }
SoilGraphExporter >> writeBehaviorDescriptions: aCollection [ 
	| unwritten |
	"write only behaviors that have not been written already"
	unwritten := aCollection reject: [ :each | versionMap includesKey: each objectId ].
	
	"write size"
	stream nextPutAll: (unwritten size asByteArrayOfSize: 8).
	unwritten do: [ :record | 
		'write behavior description', record object asString.
		"remember the current maximum version of each behavior so we can 
		easily figure out which of the objects need to be migrated"
		versionMap 
			at: record objectId 
			put: record object version.
		record objectId writeOn: stream.
		record serializeOn: stream
	].
]
