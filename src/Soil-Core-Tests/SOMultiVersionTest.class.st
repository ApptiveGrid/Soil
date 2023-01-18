Class {
	#name : #SOMultiVersionTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOMultiVersionTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SOMultiVersionTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : #tests }
SOMultiVersionTest >> testReadIsolation [
	| tx1 tx2 tx3 object |
	object := SOTestClusterRoot new nested: 'first'.
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
