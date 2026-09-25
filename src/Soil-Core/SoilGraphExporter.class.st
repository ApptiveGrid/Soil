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
		'toBeExported',
		'objectMigrations',
		'classMigrations'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilGraphExporter class >> formatVersion [
	"the version of the stream #export writes. It exists so that SoilGraphImporter refuses
	a stream it cannot read instead of misreading it - everything after this field is read
	by position, so a foreign stream would not fail, it would come out looking like data.

	Raise it when a stream from the old format could still meet a new importer. Today none
	can: an export is written and read within one operation, seconds apart, and nothing
	keeps one. So the format may change without a new number - it did when replacements
	started carrying names (Norbert, 2026-09-23). The day exports are stored, shipped or
	queued, every change needs one."
	^ 1
]

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
	0. the version of this format
	An importer that does not know it refuses the stream instead of reading it wrongly -
	see SoilGraphExporter class>>formatVersion"
	stream nextPutAll: (self class formatVersion asByteArrayOfSize: 2).
	"1. exported objects 
	A list of arbitrary object clusters to be exported"
	stream nextPut: toBeExported size. 
	toBeExported do: [ :oid |
		oid writeOn: stream .
		self processObjectId: oid ].
	"2. non-mapped objects
	These are objects that will not be serialized but still have 
	references in clusters to it. This is to prevent exporting all
	of the graph. The dangeling references need to be re-mapped by
	the importer, which finds its own object for each of them under the
	name written here"
	stream nextPut: replacements size.
	replacements keysAndValuesDo: [ :name :oid |
		self writeName: name.
		oid writeOn: stream ].
	"Now write out all reachable clusters but not the non-mapped"
	self processLoop
]

{ #category : #actions }
SoilGraphExporter >> export: aSoilObjectId [ 
	self processObjectId: aSoilObjectId.
	self processLoop
]

{ #category : #actions }
SoilGraphExporter >> exportOn: aStream [ 
	stream := aStream.
	self export
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
	replacements := Dictionary new.
	objectMigrations := Dictionary new.
	classMigrations := Dictionary new.
]

{ #category : #visiting }
SoilGraphExporter >> isUpToDateCluster: aCluster [
	
	"check if all behavior descriptions of the cluster are at the newest 
	version"
	^ aCluster behaviorDescriptions allSatisfy: [ :objectId | 
		objectId version = (versionMap at: objectId asSoilObjectId ifAbsent: false ) ]
]

{ #category : #accessing }
SoilGraphExporter >> metaSegment [ 
	^ metaSegment ifNil: [ 
		metaSegment := transaction soil objectRepository metaSegment ]
]

{ #category : #migration }
SoilGraphExporter >> migrate: aClass to: aBlock [ 
	"lookup the objectID of the behavior and store it 
	along with the block "
	migrationMap 
		at: (transaction soil behaviorRegistry 
			nameAt: aClass name 
			ifAbsent: [Error signal: 'no class found']) index 
		put: aBlock.
	"the behavior index finds the clusters that carry aClass, the class finds the objects
	in them, see SoilGraphExportSerializer"
	classMigrations at: aClass put: aBlock
]

{ #category : #migration }
SoilGraphExporter >> assertMigrationKeptItsReferences: aCluster [
	"A migration may hand back another object, but every cluster root it points at has to be
	one the database already knows. An object created while exporting has no object id - one
	is handed out when a transaction commits, and an export commits nothing - so it would go
	into the stream as a reference to index 0 and the importer would have nothing to look up.
	Say that here, where the migration is, instead of letting the record refuse it later
	without naming a cause."
	aCluster references 
		detect: [ :each | each index = 0 ]
		ifFound: [ :each |
			SoilUnsupportedError signal: 'a migration cannot introduce new cluster roots: ', 
				aCluster object class name, 
				' points at an object that has no object id yet' ]
]

{ #category : #migration }
SoilGraphExporter >> carriesMigratedBehavior: aCluster [
	^ aCluster behaviorDescriptions anySatisfy: [ :each |
		migrationMap includesKey: each index ]
]

{ #category : #migration }
SoilGraphExporter >> migrateAll: aCollection to: aBlock [ 
	aCollection do: [ :cls |
		self migrate: cls to: aBlock  ]
]

{ #category : #migration }
SoilGraphExporter >> migrateObject: anObject to: aBlock [
	"a migration for this one object rather than for every instance of its class. Use it to
	change what a single cluster carries: the cluster keeps its object id, so everything that
	points at it still does. Putting a changed copy into the object that holds it would not
	work - the copy is a new object without an id, see #assertMigrationKeptItsReferences:."
	objectMigrations 
		at: (transaction objectIdOf: anObject)
		put: aBlock
]

{ #category : #actions }
SoilGraphExporter >> migrateCluster: cluster [ 
	| block newCluster |
	block := objectMigrations 
		at: cluster objectId 
		ifAbsent: [ 
			cluster behaviorDescriptions ifEmpty: [ ^ cluster ].
			migrationMap
				at: cluster behaviorDescriptions first index
				ifAbsent: [ nil ] ].
	"a class migration is for every object of the class, the ones embedded in a cluster
	as well as the root"
	(block isNil and: [ (self carriesMigratedBehavior: cluster) not ]) 
		ifTrue: [ ^ cluster ].
	cluster 
		transaction: transaction;
		materializeObject.
	
	newCluster := cluster asNewClusterVersion.
	newCluster object: (block 
		ifNil: [ cluster object ]
		ifNotNil: [ block value: cluster object ]).
	newCluster version: 1.
	newCluster 
		transaction: transaction;
		bytes: (self serializeCluster: newCluster from: cluster object).
	self assertMigrationKeptItsReferences: newCluster.
	^ newCluster
]

{ #category : #accessing }
SoilGraphExporter >> processObjectId: oid [ 
	(self isReplaced: oid) ifTrue: [ ^ self ].
	super processObjectId: oid 
]

{ #category : #actions }
SoilGraphExporter >> replaceObject: anObject as: aName [
	"leave anObject out of the export and let the importing side put its own object in its
	place. The name is how the two sides agree on which object that is - object ids cannot
	say it, they mean nothing across databases, and counting them means the two sides have
	to register in the same order. The importer registers under the same name."
	(replacements includesKey: aName) ifTrue: [
		SoilInvalidReplacement signal:
			'an object is already registered to be replaced as ' , aName printString ].
	replacements at: aName put: (transaction objectIdOf: anObject)
]

{ #category : #testing }
SoilGraphExporter >> isReplaced: aSoilObjectId [
	"whether the caller left this object to the importing side, in which case the export
	carries references to it but not the object itself"
	^ replacements anySatisfy: [ :each | each = aSoilObjectId ]
]

{ #category : #writing }
SoilGraphExporter >> writeName: aName [
	| bytes |
	bytes := aName asString asByteArray.
	stream
		nextPut: bytes size;
		nextPutAll: bytes
]

{ #category : #configuration }
SoilGraphExporter >> skipIndexes: aCollection [ 
	indexesToSkip := aCollection collect: [ :each |
		(each class = SoilObjectId)
			ifTrue: [ each ]
			ifFalse: [ transaction objectIdOf: each  ] ]
]

{ #category : #private }
SoilGraphExporter >> serializeCluster: aCluster from: anObject [
	"aCluster object is what the migration made of anObject. Writing anObject with the
	migrated root in its place keeps what points back at anObject pointing at the root,
	see SoilGraphExportSerializer"
	^ ByteArray streamContents: [ :aStream |
		(transaction newSerializer: self serializerClass)
			migrations: classMigrations;
			replace: anObject with: aCluster object;
			stream: aStream;
			externalObjectRegistry: aCluster;
			serialize: anObject ]
]

{ #category : #accessing }
SoilGraphExporter >> serializerClass [
	^ SoilGraphExportSerializer
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
SoilGraphExporter >> visitBTreeDictionary: aBTreeDictionary [
	"An export carries a SoilSkipListDictionary and nothing else of its kind: the format
	writes an index as keySize, valueSize and maxLevel, and #readIndexOfCluster:withId:
	builds a SoilSkipList from that. A BTree would arrive as a SkipList, which works and is
	not what was exported.

	Nobody hits this - no BTree dictionary is used in Soil outside its own tests, nor in
	ApptiveGrid. It is here so that whoever is first gets told what happened instead of a
	doesNotUnderstand somewhere in the visiting."
	^ SoilUnsupportedError signal:
		  'a graph export cannot carry a ' , aBTreeDictionary class name
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
			ifFalse: [
				"each is already a live, up-to-date SoilBehaviorDescription -
				migrateCluster:/updateCluster: just materialized and re-serialized aCluster
				under the current class shape, mutating this very description in place.
				self behaviorAt: would re-read the meta segment by index, which still holds
				the OLD, not-yet-committed on-disk bytes: exporting that stale description
				would declare a field order that does not match the payload bytes we are
				about to write below, silently swapping values on import. Re-derive a fresh
				record from this exact live object instead of going back to disk."
				(transaction objectMap at: each) asNewClusterVersion
					version: 1;
					transaction: transaction;
					serializeObject;
					yourself ] ]).
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
			stream nextPutAll: (index values size asByteArrayOfSize: 8).
			index newIterator associationsDo: [ :assoc | | objectId |
				count := count + 1.
				objectId := assoc value asSoilObjectId.
				self processObjectId: objectId.
				stream 
					nextPutAll: (assoc key asByteArrayOfSize: keySize);
					nextPutAll: (objectId asByteArrayOfSize: valueSize ) ] ]
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
