Class {
	#name : #SoilTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilTest class >> classNamesNotUnderTest [
	"we for now ignore flock as this is platform specific"
	^ #(#MacOSFileLock #UnixFileLock)
]

{ #category : #accessing }
SoilTest class >> packageNamesUnderTest [
	^ #(#'Soil-Core')
]

{ #category : #accessing }
SoilTest >> path [ 
	^ 'soil-tests' asFileReference
]

{ #category : #initialization }
SoilTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem 
]

{ #category : #tests }
SoilTest >> simpleGraph [
	^ SoilTestGraphRoot new 
		nested: (SoilTestNestedObject new 
			label: 'nested under root';
			reference: (SoilTestClusterRoot new 
				nested: (SoilTestNestedObject new
					label: 'nested under cluster')))
]

{ #category : #running }
SoilTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilTest >> testCachedSegment [
	| txn |
	soil setup cacheObjectRecords: 100.
	txn := soil newTransaction.
	txn root: SoilPersistentDictionary new.
	1 to: 10 do: [ :n | | v |
		v := n asString.
		txn makeRoot: v.
		txn root at: n asString put: v ].
	txn commit.
	self assert: (soil objectRepository firstSegment cache instVarNamed: #statistics) hitRatio equals: 0.
	1 to: 10 do: [ :n | | tx |
		tx := soil newTransaction.
		tx root at: 10 atRandom asString.
		tx abort ].
	self assert: (soil objectRepository firstSegment cache instVarNamed: #statistics) hitRatio equals: 1.

]

{ #category : #tests }
SoilTest >> testChangePathToControl [ 
	soil close.
	(self path / #control) moveTo: (self path / #settings).
	soil := Soil path: self path.
	soil open.
	self assert: soil databaseVersion equals: 0
	 
	
]

{ #category : #tests }
SoilTest >> testCheckpointEmptyRecordsToCommit [
	| tx root skipList obj items |
	tx := soil newTransaction.
	root := SoilPersistentDictionary new.
	"N.B. Having the skip list at the root, did not trigger the error"
	tx makeRoot: root.
	tx root: root.
	tx checkpointAndContinue.

	skipList := SoilSkipListDictionary new keySize: 32; maxLevel: 8; yourself.
	tx makeRoot: skipList.
	tx root at: 123 put: skipList.

	obj := SoilTestClass1 new one: #oneA; yourself.
	tx makeRoot: obj.
	skipList at: 'aaa' asByteArray put: obj.

	obj := SoilTestClass1 new one: #oneB; yourself.
	tx makeRoot: obj.
	skipList at: 'bbb' asByteArray put: obj.

	tx checkpointAndContinue.

	self
		shouldnt: [
			"Doesn't always trigger error. Try more repeats, if don't see the error"
			5 timesRepeat: [
				skipList := tx root at: 123.
				"N.B. Have to actually pull in the proxy object to trigger error"
				items := skipList values collect: [ :each | each one ].
				tx checkpointAndContinue ] ]
		raise: Error
]

{ #category : #tests }
SoilTest >> testDisabledFsync [
	| tx |
	soil setup disableFsync.
	tx := soil newTransaction.
	tx root: self simpleGraph.
	self 
		shouldnt: [ tx commit ]
		raise: Error
]

{ #category : #tests }
SoilTest >> testFindRecordWithIndex [ 
	| tx skipList rec |
	tx := soil newTransaction.
	skipList := SoilSkipListDictionary new 
		maxLevel: 16;
		keySize: 10.
	tx root: { Dictionary new 
		at: #skipList put: skipList;
		yourself }.
	tx makeRoot: skipList.
	tx commit.
	rec := soil findRecord: [ :record | record usesIndexId: skipList id ].
	self assert: (rec indexIds includes: skipList id)
]

{ #category : #tests }
SoilTest >> testIncompatibleDatabaseFormatVersion [ 
	soil control databaseFormatVersion: 2.
	soil close.
	
	soil := Soil path: self path.
	self 
		should: [ soil open ]
		raise: SoilIncompatibleDatabaseFormat 
]

{ #category : #tests }
SoilTest >> testInitializeDatabase [
	self assert: (soil path / #segments / '1' / #index) exists
]

{ #category : #tests }
SoilTest >> testInitializeDatabaseFailsIfExisting [
	self 
		should: [ soil initializeFilesystem ]
		raise: Error
]

{ #category : #tests }
SoilTest >> testIsOpen [
	self assert: soil isOpen.
	soil close.
	self deny: soil isOpen
]

{ #category : #tests }
SoilTest >> testMetricsUncached [
	| tx metrics txn2 |
	soil notificationHandler: SoilMetrics new.
	tx := soil newTransaction.
	tx root: self simpleGraph.
	tx commit.
	metrics := soil notificationHandler.
	self assert: metrics transactionsCreated equals: 1.
	self assert: metrics transactionsCommittedWrite equals: 1.
	self assert: metrics transactionsCommittedReadOnly equals: 0.
	self assert: metrics objectRecordsRead equals: 0.
	self assert: metrics objectRecordCacheHits equals: 0.
	self assert: metrics objectRecordsWritten equals: 1.
	self assert: metrics metaRecordsRead equals: 0.
	self assert: metrics metaRecordsWritten equals: 3.
	txn2 := soil newTransaction.
	txn2 root.
	txn2 commit.
	self assert: metrics transactionsCreated equals: 2.
	self assert: metrics transactionsCommittedWrite equals: 1.
	self assert: metrics transactionsCommittedReadOnly equals: 1.
	self assert: metrics objectRecordsRead equals: 1.
	self assert: metrics objectRecordCacheHits equals: 0.
	self assert: metrics objectRecordCacheHitRatio equals: 0.
	self assert: metrics objectRecordsWritten equals: 1.
	self assert: metrics metaRecordsRead equals: 3.
	self assert: metrics metaRecordCacheHits equals: 0.
	self assert: metrics metaRecordsWritten equals: 3.
	self assert: metrics metaRecordCacheHitRatio equals: 0.


]

{ #category : #tests }
SoilTest >> testMetricsWithRecordCache [
	| tx metrics txn2 |
	soil setup cacheRecords.
	soil notificationHandler: SoilMetrics new.
	tx := soil newTransaction.
	tx root: self simpleGraph.
	tx commit.
	metrics := soil notificationHandler.
	self assert: metrics transactionsCreated equals: 1.
	self assert: metrics transactionsCommittedWrite equals: 1.
	self assert: metrics transactionsCommittedReadOnly equals: 0.
	self assert: metrics objectRecordsRead equals: 0.
	self assert: metrics objectRecordCacheHits equals: 0.
	self assert: metrics objectRecordCacheMisses equals: 0.
	self assert: metrics objectRecordCacheHitRatio equals: 0.
	self assert: metrics objectRecordsWritten equals: 1.
	self assert: metrics metaRecordsRead equals: 0.
	self assert: metrics metaRecordsWritten equals: 3.
	txn2 := soil newTransaction.
	txn2 root.
	txn2 commit.
	self assert: metrics transactionsCreated equals: 2.
	self assert: metrics transactionsCommittedWrite equals: 1.
	self assert: metrics transactionsCommittedReadOnly equals: 1.
	"written clusters are cached so there should be no reads"
	self assert: metrics objectRecordsRead equals: 0.
	"instead there is one record read for the root"
	self assert: metrics objectRecordCacheHits equals: 1.
	self assert: metrics objectRecordCacheMisses equals: 0.
	self assert: metrics objectRecordCacheHitRatio equals: 1.

	self assert: metrics objectRecordsWritten equals: 1.
	"written clusters are cached so there should be no reads"
	self assert: metrics metaRecordsRead equals: 0.
	"instead the meta cache should have three hits (three classes in root)"
	self assert: metrics metaRecordCacheHits equals: 3.
	self assert: metrics metaRecordCacheMisses equals: 0.
	self assert: metrics metaRecordCacheHitRatio equals: 1.
	self assert: metrics metaRecordsWritten equals: 3.


]

{ #category : #tests }
SoilTest >> testSerializingClassDescription [
	| obj bytes obj2 stream transaction |
	self skip.
	obj :=  { #C -> (SoilBehaviorDescription for: SOTestClusterAlwaysRoot ) } asDictionary.
	stream := ByteArray new writeStream.
	transaction := soil newTransaction.
	SoilSerializer new
		soil: soil;
		transaction: transaction;
		stream: stream; 
		serialize: obj.
	bytes := stream contents.
	obj2 := SoilMaterializer new 
		soil: soil;
		transaction: transaction;
		stream: bytes readStream;
		materialize.
	self assert: (obj2 at: #C) class equals: SoilBehaviorDescription   
	
]

{ #category : #tests }
SoilTest >> testSerializingRootOneCluster [
	| tx tx2 materializedRoot |
	tx := soil newTransaction.
	tx root: self simpleGraph.
	tx commit.
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot nested reference class equals: SoilTestClusterRoot  
	
]

{ #category : #tests }
SoilTest >> testSerializingRootTwoCluster [
	| tx tx2 materializedRoot graph |
	tx := soil newTransaction.
	graph := self simpleGraph.
	tx makeRoot: graph nested reference. 
	tx root: graph. 
	tx checkpoint.
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot nested reference objectIsNotLoaded.
	self assert: materializedRoot nested reference isSoilProxy.
	self assert: materializedRoot nested reference nested label equals: 'nested under cluster'.	
]

{ #category : #tests }
SoilTest >> testSerializingToSavedRoot [
	| tx theRoot modelMap modelName theModel tx2 soil2 tx3 soil3 materializedRoot materializedModelMap |
	tx := soil newTransaction.
	theRoot := Dictionary new.
	tx root: theRoot.
	tx commit.
	soil2 := (Soil path: soil path) open.
	tx2 := soil2 newTransaction.
	theRoot := tx2 root.
	"theRoot := Dictionary new.
	tx2 root: theRoot."
	theModel := self simpleGraph.
	modelName := theModel class name.
	modelMap := Dictionary new.
	theRoot at: modelName put: modelMap.
	tx2 markDirty: theRoot.
	tx2 makeRoot: modelMap.
	modelMap at: 'foo' put: theModel.
	tx2 commit.

	soil3 := (Soil path: soil path) open.
	tx3 := soil3 newTransaction.
	materializedRoot := tx3 root.
	materializedModelMap := materializedRoot at: modelName.
	self assert: materializedModelMap class equals: SoilObjectProxy.
	self assert: materializedModelMap soilRealObject class equals: Dictionary.
	self assert: (materializedModelMap soilRealObject at: 'foo') class equals: SoilTestGraphRoot.
	self assert: (materializedModelMap soilRealObject at: 'foo') nested reference nested label equals: 'nested under cluster'
]

{ #category : #tests }
SoilTest >> testSetupMetaRecords [ 
	soil setup 
		cacheMetaRecords: 100.
	self assert: soil objectRepository metaSegment class equals: SoilCachedObjectSegment.
	self assert: (soil objectRepository metaSegment cache instVarNamed: #weight) maximum equals: 100.
	self assert: soil objectRepository firstSegment class equals: SoilObjectSegment 
]

{ #category : #tests }
SoilTest >> testSetupObjectRecords [ 
	soil setup 
		cacheObjectRecords: 1000.
	self assert: soil objectRepository firstSegment class equals: SoilCachedObjectSegment.
	self assert: (soil objectRepository firstSegment cache instVarNamed: #weight) maximum equals: 1000.
	self assert: soil objectRepository metaSegment class equals: SoilObjectSegment 
]

{ #category : #tests }
SoilTest >> testUpdatingPersistentObject [
	| tx updateTx persistedRoot readTx root3 |
	tx := soil newTransaction.
	tx root: self simpleGraph.
	tx commit.
	updateTx := soil newTransaction.
	persistedRoot := updateTx root.
	persistedRoot nested reference nested label: 'update nested under cluster'.
	updateTx markDirty: persistedRoot.
	updateTx commit.
	readTx := soil newTransaction.
	root3 := readTx root.
	self assert: root3 nested reference nested label equals: 'update nested under cluster' 
	
]
