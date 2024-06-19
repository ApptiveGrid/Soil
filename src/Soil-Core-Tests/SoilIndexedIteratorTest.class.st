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
	
	"first when the first one was removed"
	iterator := index newIterator.
	iterator at: 1 put: (1 asByteArrayOfSize: 8).
	iterator at: 2 put: (2 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator := index newIterator.
	self assert: iterator firstAssociation value equals: (2 asByteArrayOfSize: 8).
	
	"lets remove the two first ones"
	iterator := index newIterator.
	iterator at: 1 put: (1 asByteArrayOfSize: 8).
	iterator at: 2 put: (2 asByteArrayOfSize: 8).
	iterator at: 3 put: (3 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator removeKey: 2.
	iterator := index newIterator.
	self assert: iterator firstAssociation value equals: (3 asByteArrayOfSize: 8)
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
SoilIndexedIteratorTest >> testPrevious [
	
	| capacity iterator value toFind |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList ifTrue: [ 254 ] ifFalse: [ 255 ].
	"the key is indeed the first one in the page"
	self assert: (iterator findPageFor: toFind) firstItem key equals: toFind.
	
	iterator := index newIterator.
	value := iterator
		find: toFind;
		previous.
	self assert: value equals: ((toFind - 1) asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPrevious5 [
	
	| capacity iterator result |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	result := iterator
		find: 6;
		previous: 5.
	self assert: result size equals: 5.
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPreviousAssociation [
	
	| capacity iterator value toFind |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList ifTrue: [ 254 ] ifFalse: [ 255 ].
	"the key is indeed the first one in the page"
	self assert: (iterator findPageFor: toFind) firstItem key equals: toFind.
	
	iterator := index newIterator.
	value := iterator
		find: toFind;
		previousAssociation.
	self assert: value value equals: ((toFind - 1) asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPreviousAssociationFirstPage [
	
	| capacity iterator value  |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	
	"prior of first"
	iterator := index newIterator.
	value := iterator
		find: 1;
		previousAssociation.
	self assert: value value equals: nil.
	
	"prior of last"
	iterator := index newIterator.
	value := iterator
		find: capacity;
		previousAssociation.
	self assert: value value equals: (capacity - 1 asByteArrayOfSize: 8).
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPreviousAssociationNonBoundary [
	"check previousAssociation where we have to *not* cross a page boundary"
	
	| capacity iterator value toFind |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	
	"select a key where we do not have to cross over to another page"
	toFind := index class == SoilSkipList ifTrue: [ 255 ] ifFalse: [ 256 ].
	"the key is indeed not the first one in the page"
	self deny: (iterator findPageFor: toFind) firstItem key equals: toFind.
	
	iterator := index newIterator.
	value := iterator
		find: toFind;
		previousAssociation.
	self assert: value value equals: ((toFind - 1) asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPreviousPage [
	
	| capacity iterator page toFind priorPage |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList ifTrue: [ 254 ] ifFalse: [ 255 ].
	"the key is indeed the first one in the page"
	self assert: (iterator findPageFor: toFind) firstItem key equals: toFind.
	
	iterator := index newIterator.
	priorPage := iterator
		find: toFind;
		previousPage.
		
	iterator := index newIterator.
	page := iterator findPageFor: toFind.
			
	self assert: priorPage next equals: page index
]

{ #category : #tests }
SoilIndexedIteratorTest >> testPreviousPageFirstPage [
	
	| capacity iterator |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	iterator firstPage. "set iterator currentPage to first page"
	self assert: iterator previousPage equals: nil
]
