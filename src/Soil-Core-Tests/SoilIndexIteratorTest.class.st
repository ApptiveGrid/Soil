Class {
	#name : #SoilIndexIteratorTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'index',
		'classToTest'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #'building suites' }
SoilIndexIteratorTest class >> testParameters [
	"even though we test the iterators, the test creates the indexes and gets the iterators from there"
	^ ParametrizedTestMatrix new
		addCase: { #classToTest -> SoilSkipList };
		addCase: { #classToTest -> SoilBTree };
		yourself
]

{ #category : #accessing }
SoilIndexIteratorTest >> classToTest [

	^ classToTest
]

{ #category : #accessing }
SoilIndexIteratorTest >> classToTest: anObject [

	classToTest := anObject
]

{ #category : #running }
SoilIndexIteratorTest >> setUp [ 
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
SoilIndexIteratorTest >> tearDown [ 
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : #tests }
SoilIndexIteratorTest >> testFindAndNext [
	
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
SoilIndexIteratorTest >> testFindAndNext2 [
	
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
SoilIndexIteratorTest >> testFirst [
	
	| capacity first |
	capacity := index headerPage itemCapacity * 2.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	first := index newIterator first.
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ].
	"we get always the first"
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ].
	
	first := index newIterator first: 3.
	self assert: first size equals: 3.
	self assert: first third equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: first first equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilIndexIteratorTest >> testFirstWithRemovedItem [ 
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
SoilIndexIteratorTest >> testLast [
	
	| capacity last |
	capacity := index headerPage itemCapacity * 2.
	
	"check last on empty iterator"
	self assert: index newIterator last equals: nil.
	
	1 to: capacity - 1  do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	last := index newIterator last.
	self assert: last equals: #[ 8 7 6 5 4 3 2 1 ].
	
	last := index newIterator last: 3.
	self assert: last size equals: 3.
	self assert: last first equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: last third equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilIndexIteratorTest >> testLastAssociation [
	| iterator |
	
	"test empty index"
	iterator := index newIterator.
	self assert: iterator lastAssociation isNil.
	
	"lastAssociation always returns last"
	iterator := index newIterator.
	iterator at: 1 put: (1 asByteArrayOfSize: 8).
	iterator at: 2 put: (2 asByteArrayOfSize: 8).

	self assert: iterator lastAssociation value equals: (2 asByteArrayOfSize: 8).
	self assert: iterator lastAssociation value equals: (2 asByteArrayOfSize: 8).
]

{ #category : #tests }
SoilIndexIteratorTest >> testLastPage [
	
	| capacity lastPage |
	capacity := index headerPage itemCapacity * 2.
	
	"check last on empty iterator"
	self assert: index newIterator lastPage identicalTo: index headerPage.
	
	1 to: capacity - 1  do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	lastPage := index newIterator lastPage.
	self assert: lastPage lastItem value equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilIndexIteratorTest >> testLastWithRemovedItem [ 
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
SoilIndexIteratorTest >> testPrevious [
	
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
SoilIndexIteratorTest >> testPrevious5 [
	
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
SoilIndexIteratorTest >> testPreviousAssociation [
	
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
SoilIndexIteratorTest >> testPreviousAssociationFirstPage [
	
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
SoilIndexIteratorTest >> testPreviousAssociationNonBoundary [
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
SoilIndexIteratorTest >> testPreviousPage [
	
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
SoilIndexIteratorTest >> testPreviousPageFirstPage [
	
	| capacity iterator |
	
	"fisrt check on empty"
	iterator := index newIterator.
	iterator firstPage. "set iterator currentPage to first page"
	self assert: iterator previousPage equals: nil.
	
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	iterator firstPage. "set iterator currentPage to first page"
	self assert: iterator previousPage equals: nil
]
