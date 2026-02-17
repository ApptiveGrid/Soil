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
		'behaviors',
		'clusters',
		'replacements',
		'toBeExported'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #adding }
SoilGraphExporter >> addObject: anObject [ 
	self addObjectId: (transaction objectIdOf: anObject)
]

{ #category : #adding }
SoilGraphExporter >> addObjectId: aSoilObjectId [ 
	toBeExported add: aSoilObjectId 
]

{ #category : #adding }
SoilGraphExporter >> addObjects: aCollection [ 
	aCollection do: [ :each |
		self addObject: each ]
	
]

{ #category : #visiting }
SoilGraphExporter >> behaviorAt: index [ 
	^ behaviors 
		at: index 
		ifAbsentPut: [ 
			 transaction materializeRecord: (self metaSegment at: index) ]

]

{ #category : #actions }
SoilGraphExporter >> export [
	"export format: 
	1. exported objects 
	A list of arbitrary object clusters to be exported"
	stream nextPut: toBeExported size. 
	toBeExported do: [ :oid |
		oid writeOn: stream .
		self processObjectId: oid ].
	"2. non-mapped objects
	These are objects that will not be serialized but still have 
	references in clusters to it. This is to prevent exporting all
	of the graph. The dangeling references need to be re-mapped by
	the importer"
	stream nextPut: replacements size.
	replacements do: [ :oid |
		oid writeOn: stream ].
	"Now write out all reachable clusters but not the non-mapped"
	self processLoop
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
	clusters := 0.
	toBeExported := OrderedCollection new.
	replacements := OrderedCollection new.
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
		metaSegment := transaction soil objectRepository metaSegment ].

]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> migrate: aClass to: aBlock [ 
	"lookup the objectID of the behavior and store it 
	along with the block "
	migrationMap 
		at: (transaction soil behaviorRegistry 
			nameAt: aClass name 
			ifAbsent: [Error signal: 'no class found']) index 
		put: aBlock 

]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> migrateAll: aCollection to: aBlock [ 
	aCollection do: [ :cls |
		self migrate: cls to: aBlock  ]
]

{ #category : #actions }
SoilGraphExporter >> migrateCluster: cluster [ 
	| block newCluster |
	cluster behaviorDescriptions ifEmpty: [ ^ cluster ].
	block := migrationMap
		at: cluster behaviorDescriptions first index
		ifAbsent: [ ^ cluster ].
	cluster 
		transaction: transaction;
		materializeObject.
	
	newCluster := cluster asNewClusterVersion.
	newCluster object: (block value: cluster object).
	newCluster version: 1.
	newCluster 
		transaction: transaction;
		serializeObject.
	^ newCluster
]

{ #category : #accessing }
SoilGraphExporter >> processObjectId: oid [ 
	(replacements includes: oid) ifTrue: [ ^ self ].
	super processObjectId: oid 
]

{ #category : #'as yet unclassified' }
SoilGraphExporter >> replaceObject: anObject [
	replacements add: (transaction objectIdOf: anObject)
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
	transaction := aTransaction.
	soil := aTransaction soil 
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
			transaction: transaction;
			serializeObject;
			yourself.
	transaction registerRecord: cluster.
	^ cluster
			
]

{ #category : #visiting }
SoilGraphExporter >> visitPersistentClusterVersion: aCluster [ 
	| cluster |
	clusters := clusters + 1.
	"remove all information regarding the current segment as it
	will be invalid when exported"
	aCluster detachFromSegment.

	"write format objectId, behaviors, cluster, index settings"
	aCluster objectId writeOn: stream.
	 
	cluster := self migrateCluster: aCluster.
	(cluster == aCluster) ifTrue: [ 
		 cluster := self updateCluster: aCluster ].
	
	self writeBehaviorDescriptions: (cluster behaviorDescriptions collect: [:each | 
		(each isKindOf: SoilVersionedObjectId)
			ifTrue: [ self behaviorAt: each index ]
			ifFalse: [ self behaviorAt: each objectId index ] ]).
	"write the cleaned and up-to-date cluster"
	cluster 
		transaction: transaction;
		serializeOn: stream .
	"for all indexes being used remember the index setting for it "
	cluster references do: [ :reference |
		"(oidsToIgnore includes: reference) ifTrue: [ self halt ]."
		self processObjectId: reference ].
	cluster indexIds ifNotEmpty: [ 
		cluster object ifNil: [  
			transaction registerRecord: (cluster 
				transaction: transaction;
				materializeObject;
				yourself) ].
		self visit: cluster object ].
]

{ #category : #visiting }
SoilGraphExporter >> visitSkipListDictionary: aSkipListDictionary [ 
	| index count keySize valueSize maxLevel |
	index := aSkipListDictionary index wrapped.
	keySize := index keySize.
	valueSize := index valueSize.
	maxLevel := index maxLevel.
	stream 
			nextPutAll: ( keySize asByteArrayOfSize: 2);
			nextPutAll: ( valueSize asByteArrayOfSize: 2 );
			nextPutAll: ( maxLevel asByteArrayOfSize: 2 ).
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
					nextPutAll: (assoc key asByteArrayOfSize: keySize);
					nextPutAll: (assoc value asByteArrayOfSize: valueSize ) ] ]
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
