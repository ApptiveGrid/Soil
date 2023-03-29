Class {
	#name : #SOTransactionTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SOTransactionTest >> setUp [ 
	super setUp.
	soil := Soil new 
		path: 'sunit-soil-tests';
		destroy;
		initializeFilesystem;
		yourself.
]

{ #category : #running }
SOTransactionTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SOTransactionTest >> testAddSameObjectIdTwice [
	| tx |
	tx := SOTransaction new.
	tx atObjectId: (SOObjectId segment: 1 index: 0) putObject: Object new. 
	tx atObjectId: (SOObjectId segment: 1 index: 0) putObject: Object new. 
	self assert: tx dirtyObjects size equals: 2
]

{ #category : #tests }
SOTransactionTest >> testConflictingReadVersion [
	| obj tx1 tx2 tx3 |
	obj := SOTestGraphRoot new 
		nested: (SOTestNestedObject new label: 'first').
	"make object to test to be in database"
	tx1 := soil newTransaction.
	tx1 root: obj.
	tx1 commit.
	"open a transaction, modify but do not commit"
	tx2 := soil newTransaction.
	tx2 root nested label: 'second'.
	tx2 markDirty: tx2 root.
	"open concurrent transaction, make concurrent modification
	and commit"
	tx3 := soil newTransaction.
	tx3 root nested label: 'third'.
	tx3 markDirty: tx3 root.
	tx3 commit.
	"when trying to commit the second transaction the concurrent
	modification should throw an exception"
	self 
		should: [ tx2 commit ]
		raise: SOObjectHasConcurrentChange 
]

{ #category : #tests }
SOTransactionTest >> testEmptyAbort [
	| tx |
	tx := SOTransaction new.
	tx root: Object new.
	tx abort.
	self assert: tx isAborted
]

{ #category : #tests }
SOTransactionTest >> testTwoRootsWithAlwaysRoot [
	| tx obj1 obj2 |
	tx := soil newTransaction.
	obj1 := SOTestGraphRoot new.
	obj2 := SOTestClusterAlwaysRoot new.
	obj1 nested: obj2.
	tx makeRoot: obj1.
	self assert: tx records size equals: 1.
	"obj1 is made root but refers to an object that has a class
	side setting for being root. The second object is being made
	root when serializing obj1 "
	tx checkpoint.
	"expect 4 records: 2 instances and 2 classes"
	self assert: tx records size equals: 4
]

{ #category : #tests }
SOTransactionTest >> testTwoRootsWithMakeRoot [
	| tx obj1 obj2 |
	tx := soil newTransaction.
	obj1 := Object new.
	obj2 := Object new.
	tx makeRoot: obj1.
	tx makeRoot: obj2.
	self assert: tx records size equals: 2
]
