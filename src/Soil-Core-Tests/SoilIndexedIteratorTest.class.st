Class {
	#name : #SoilIndexedIteratorTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'index',
		'classToTest'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #'building suites' }
SoilIndexedIteratorTest class >> testParameters [
	"even though we test the iterators, the test creates the indexes and gets the iterators from there"
	^ ParametrizedTestMatrix new
		addCase: { #classToTest -> SoilSkipList };
		addCase: { #classToTest -> SoilBTree };
		yourself
]

{ #category : #accessing }
SoilIndexedIteratorTest >> classToTest [

	^ classToTest
]

{ #category : #accessing }
SoilIndexedIteratorTest >> classToTest: anObject [

	classToTest := anObject
]

{ #category : #running }
SoilIndexedIteratorTest >> setUp [ 
	super setUp.

	index := classToTest new
		path: 'sunit-indexIteratorTest';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 8;
		valueSize: 8;
		maxLevel: 4; "ignored for BTree"
	   yourself
		
]

{ #category : #running }
SoilIndexedIteratorTest >> tearDown [ 
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : #tests }
SoilIndexedIteratorTest >> testFindAndNext [
	
	| capacity iterator value |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	value := iterator
		find: 222;
		next.
	self assert: value equals: (223 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexedIteratorTest >> testFindAndNext2 [
	
	| capacity iterator values |
	capacity := index firstPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	values := iterator
		find: 222;
		next: 3.
	self assert: values size equals: 3.
	self assert: values asArray equals: {(223 asByteArrayOfSize: 8). (224 asByteArrayOfSize: 8). (225 asByteArrayOfSize: 8)}.
	"test requesting more at the end when the are not enough entries"
	values := iterator
		find: capacity-1;
		next: 3.
	"size is 1"
	self assert: values size equals: 1.
	"and we get the right value"
	self assert: values asArray equals: {(capacity asByteArrayOfSize: 8)}
]

{ #category : #tests }
SoilIndexedIteratorTest >> testFirst [
	
	| capacity first |
	capacity := index headerPage itemCapacity * 2.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	first := index newIterator first.
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilIndexedIteratorTest >> testFirstWithRemovedItem [ 
	| iterator |
	
	iterator := index newIterator.
	iterator at: 1 put: (1 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator := index newIterator.
	self assert: iterator firstAssociation value equals: nil.
	
	self flag: #TODO. 
	"need to test with two items, remove first, three items, remove first two"
]

{ #category : #tests }
SoilIndexedIteratorTest >> testLastWithRemovedItem [ 
	| iterator |
	
	iterator := index newIterator.
	iterator at: 1 put: (1 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator := index newIterator.
	self assert: iterator lastAssociation equals: nil.
	
	"last when the last one was removed"
	iterator := index newIterator.
	iterator at: 1 put: (1 asByteArrayOfSize: 8).
	iterator at: 2 put: (2 asByteArrayOfSize: 8).
	iterator removeKey: 2.
	
	iterator := index newIterator.
	self assert: iterator lastAssociation value equals: (1 asByteArrayOfSize: 8).
	
	"lets remove the two last ones"
	iterator := index newIterator.
	iterator at: 2 put: (2 asByteArrayOfSize: 8).
	iterator at: 3 put: (3 asByteArrayOfSize: 8).
	iterator removeKey: 3.
	iterator removeKey: 2.
	iterator := index newIterator.
	self assert: iterator lastAssociation value equals: (1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPrior [
	
	| capacity iterator value toFind |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList ifTrue: [ 254 ] ifFalse: [ 255 ].
	value := iterator
		find: toFind;
		prior.
	self assert: value equals: ((toFind - 1) asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPrior5 [
	
	| capacity iterator result |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	result := iterator
		find: 6;
		prior: 5.
	self assert: result size equals: 5.
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPriorAssociation [
	
	| capacity iterator value toFind |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList ifTrue: [ 254 ] ifFalse: [ 255 ].
	value := iterator
		find: toFind;
		priorAssociation.
	self assert: value value equals: ((toFind - 1) asByteArrayOfSize: 8)
]
