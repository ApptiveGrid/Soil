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
		initializeFilesystem;
		yourself.
]

{ #category : #running }
SOTransactionTest >> tearDown [ 
	super tearDown.
	soil destroy
]

{ #category : #tests }
SOTransactionTest >> testAddSameIdTwice [
	| tx |
	tx := SOTransaction new.
	tx atObjectId: (SOObjectId segment: 1 index: 0) putObject: Object new. 
	tx atObjectId: (SOObjectId segment: 1 index: 0) putObject: Object new. 
	self assert: tx dirtyObjects size equals: 2
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
