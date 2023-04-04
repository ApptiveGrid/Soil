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
	obj1 := SOTestClusterRoot new nested: 'object1'.
	tx makeRoot: obj1.
	obj2 := SOTestClusterRoot new nested: 'object2'.
	tx makeRoot: obj2.
	dict := SoilSkipListDictionary new
		keySize: 8;
		maxLevel: 4.
	tx root: dict.
	self halt.
	dict 
		at: #foo put: obj1;
		at: #boo put: obj2.
		self halt.
	tx commit.
	tx2 := soil newTransaction.
	self assert: (tx2 root at: #foo) nested equals: 'object1'.
	self assert: (tx2 root at: #boo) nested equals: 'object2'


]
