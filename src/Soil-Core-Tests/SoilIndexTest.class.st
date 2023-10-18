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
SoilIndexTest >> testConcurrentAddKey [ 
	| tx1 tx2 tx3 |
	tx1 := soil newTransaction.
	tx1 root: (SoilSkipListDictionary new 
		maxLevel: 8;
		keySize: 16;
		at: #one put: #onevalue;
		yourself).
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and add a key to 
	the dictionary which should be invisible to tx2"
	tx3 := soil newTransaction.
	tx3 root
		at: #two put: #twovalue.
	tx3 commit.
	self assert: (tx2 root at: #one) equals: #onevalue.
	self assert: (tx2 root at: #two ifAbsent: [ #notfound ]) equals: #notfound
]

{ #category : #tests }
SoilIndexTest >> testConcurrentDo [
	| tx1 tx2 tx3 col |
	tx1 := soil newTransaction.
	tx1 root: (SoilSkipListDictionary new 
		maxLevel: 8;
		keySize: 16;
		at: #one put: #onevalue;
		at: #two put: #twovalue;
		at: #three put: #threevalue;
		at: #four put: #fourvalue;
		yourself).
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and add a key to 
	the dictionary which should be invisible to tx2"
	tx3 := soil newTransaction.
	tx3 root
		at: #five put: #fivevalue.
	tx3 commit.
	col := OrderedCollection new.
	tx2 root do: [ :each |
		col add: each ].
	self assert: col size  equals: 4.
	self assert: (col noneSatisfy: [:each | each = #fiveValue ]).

]

{ #category : #tests }
SoilIndexTest >> testConcurrentIsEmpty [ 
	| tx1 tx2 tx3 |
	tx1 := soil newTransaction.
	tx1 root: (SoilSkipListDictionary new 
		maxLevel: 8;
		keySize: 16;
		at: #one put: #onevalue;
		yourself).
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and add a key to 
	the dictionary which should be invisible to tx2"
	tx3 := soil newTransaction.
	tx3 root removeKey: #one.
	tx3 commit.
	self assert: tx2 root size equals: 0.
	self assert: tx2 root isEmpty.
]

{ #category : #tests }
SoilIndexTest >> testConcurrentRemoveKey [ 
	| tx1 tx2 tx3 |
	tx1 := soil newTransaction.
	tx1 root: (SoilSkipListDictionary new 
		maxLevel: 8;
		keySize: 16;
		at: #one put: #onevalue;
		yourself).
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and remove a key to 
	the dictionary which should still be visible to tx2"
	tx3 := soil newTransaction.
	tx3 root
		removeKey: #one.
	tx3 commit.
	self assert: (tx2 root at: #one) equals: #onevalue.

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
	self assert: root1 index wrappedSkipList pages size equals: 2.
	root1 index flushCachedPages.
	self assert: root1 index pages size equals: 0.
	txn1 abort.

	txn2 := soil newTransaction.
	root2 := txn2 root.
	self assert: root2 index pages size equals: 0.
	self assert: root2 index wrappedSkipList pages size equals: 0.
	self assert: (root2 at: '56') equals: '56'.
	txn2 abort
 

]
