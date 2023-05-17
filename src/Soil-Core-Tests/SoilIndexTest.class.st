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
SoilIndexTest >> testIndexCreation [ 
	| tx dict obj1 obj2 |
	tx := soil newTransaction.
	obj1 := Object new.
	tx makeRoot: obj1.
	obj2 := Object new.
	tx makeRoot: obj2.
	dict := SoilSkipListDictionary new
		keySize: 32;
		maxLevel: 8.
	tx root: dict.
	dict 
		at: #foo put: obj1;
		at: #boo put: obj2.
	tx commit.

]

{ #category : #tests }
SoilIndexTest >> testIndexCreationAndRead [
	| tx dict obj1 obj2 tx2 |
	tx := soil newTransaction.
	obj1 := SoilTestClusterRoot new nested: 'object1'.
	tx makeRoot: obj1.
	obj2 := SoilTestClusterRoot new nested: 'object2'.
	tx makeRoot: obj2.
	dict := SoilSkipListDictionary new
		keySize: 8;
		maxLevel: 4.
	tx root: dict.
	dict 
		at: #foo put: obj1;
		at: #boo put: obj2.
	tx commit.
	tx2 := soil newTransaction.
	self assert: (tx2 root at: #foo) nested equals: 'object1'.
	self assert: (tx2 root at: #boo) nested equals: 'object2'


]
