Class {
	#name : #SoilIndexTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SoilIndexTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'soil-tests')
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilIndexTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilIndexTest >> testFlushIndexPages [
	| tx dict capacity txn2 txn1 root1 root2 |
	tx := soil newTransaction.
	dict := SoilSkipListDictionary new
		keySize: 16;
		maxLevel: 8.
	tx root: dict.
	capacity := (dict index pageAt: 1) itemCapacity.
	1 to: capacity + 1 do: [ :n | 
		dict at: n asString put: n asString ].
	tx commit.
	txn1 := soil newTransaction.
	root1 := txn1 root.
	self assert: root1 index wrapped pages size equals: 2.
	root1 index flushCachedPages.
	self assert: root1 index pages size equals: 0.
	txn1 abort.

	txn2 := soil newTransaction.
	root2 := txn2 root.
	self assert: root2 index pages size equals: 0.
	self assert: root2 index wrapped pages size equals: 0.
	self assert: (root2 at: '56') equals: '56'.
	txn2 abort
 

]
