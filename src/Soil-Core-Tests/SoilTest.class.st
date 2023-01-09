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
	^ #(#SOMacOsFileLock #SOUnixFileLock)
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
	^ SOTestGraphRoot new 
		nested: (SOTestNestedObject new 
			label: 'nested under root';
			reference: (SOTestClusterRoot new 
				nested: (SOTestNestedObject new
					label: 'nested under cluster')))
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
	obj :=  { #C -> (SOBehaviorDescription for: SOTestClusterAlwaysRoot ) } asDictionary.
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
	self assert: (obj2 at: #C) class equals: SOBehaviorDescription   
	
]

{ #category : #tests }
SoilTest >> testSerializingRootOneCluster [
	| tx tx2 materializedRoot |
	tx := soil newTransaction.
	tx root: self simpleGraph.
	tx commit.
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot nested reference class equals: SOTestClusterRoot  
	
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
	self assert: materializedRoot nested reference class equals: SOObjectProxy.
	self assert: materializedRoot nested reference nested label equals: 'nested under cluster'
	
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
