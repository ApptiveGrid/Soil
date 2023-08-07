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
	^ 'soil-tests'
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
SoilTest >> testIncompatibleDatabaseFormatVersion [ 
	soil settings databaseFormatVersion: 2.
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
