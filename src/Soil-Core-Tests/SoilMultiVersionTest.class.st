Class {
	#name : 'SoilMultiVersionTest',
	#superclass : 'TestCase',
	#instVars : [
		'soil'
	],
	#category : 'Soil-Core-Tests',
	#package : 'Soil-Core-Tests'
}

{ #category : 'accessing' }
SoilMultiVersionTest >> path [ 
	^ 'soil-tests'
]

{ #category : 'initialization' }
SoilMultiVersionTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : 'running' }
SoilMultiVersionTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : 'tests' }
SoilMultiVersionTest >> testReadIsolation [
	| tx1 tx2 tx3 object |
	object := SoilTestClusterRoot new nested: 'first'.
	tx1 := soil newTransaction.
	tx1 root: object.
	tx1 commit.
	
	tx2 := soil newTransaction.
	tx3 := soil newTransaction.
	
	tx2 root nested: 'second'.
	tx2 markDirty: tx2 root.
	tx2 commit.
	
	self assert: tx3 root nested equals: 'first' 
]
