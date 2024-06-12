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
SoilIndexedIteratorTest >> testIteratorFindAndNext [
	
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
SoilIndexedIteratorTest >> testIteratorFindAndNext2 [
	
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
SoilIndexedIteratorTest >> testIteratorFirst [
	
	| capacity first |
	capacity := index headerPage itemCapacity * 2.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	first := index newIterator first.
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilIndexedIteratorTest >> testIteratorFirstWithSingleRemovedItem [ 
	| iterator |
	iterator := index newIterator.
	iterator at: #foo put: #bar.
	iterator removeKey: #foo.
	self assert: iterator firstAssociation equals: nil
]

{ #category : #tests }
SoilIndexedIteratorTest >> testIteratorLastWithSingleRemovedItem [ 
	| iterator |
	iterator := index newIterator.
	iterator at: #foo put: #bar.
	iterator removeKey: #foo.
	self assert: iterator lastAssociation equals: nil
]
