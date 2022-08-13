Class {
	#name : #SoilTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SoilTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil cleanFiles
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
	soil initializeDatabase.
	self assert: (soil path / #segments / '1' / #index) exists
]

{ #category : #tests }
SoilTest >> testSerializingRootOneCluster [
	| tx tx2 materializedRoot |
	tx := soil newTransaction.
	tx root: self simpleGraph.
	tx commit.
	self assert: (soil path / '1') exists.
	self deny: (soil path / '2') exists.
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
	tx commit.
	self assert: (soil path / '1') exists.
	self assert: (soil path / '2') exists.
	tx2 := soil newTransaction.
	materializedRoot := tx2 root.
	self assert: materializedRoot nested reference class equals: SOProxy.
	self assert: materializedRoot nested reference nested label equals: 'nested under cluster'
	
]
