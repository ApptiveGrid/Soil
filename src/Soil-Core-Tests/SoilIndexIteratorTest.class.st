Class {
	#name : #SoilIndexIteratorTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'index',
		'classToTest',
		'uniqueKeys'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #'building suites' }
SoilIndexIteratorTest class >> testParameters [
	"even though we test the iterators, the test creates the indexes and gets the iterators from there"
	^ ParametrizedTestMatrix new
		addCase: { #classToTest -> SoilSkipList . #uniqueKeys -> true};
		addCase: { #classToTest -> SoilBTree . #uniqueKeys -> true};
		addCase: { #classToTest -> SoilSkipList . #uniqueKeys -> false};
		addCase: { #classToTest -> SoilBTree . #uniqueKeys -> false};
		yourself
]

{ #category : #running }
SoilIndexIteratorTest >> assertSoilDuplicate: actual equals: expected [
	uniqueKeys
		ifTrue: [self assert: actual equals: expected  ]
		ifFalse: [ self assertCollection: actual hasSameElements: {expected} ] 
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
		uniqueKeys: uniqueKeys;
	   yourself
		
]

{ #category : #running }
SoilIndexIteratorTest >> tearDown [ 
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : #tests }
SoilIndexIteratorTest >> testAddRandom [

	| iterator numEntries entries |
	"just some random adding and checking that we can find it, configured to create lots of pages"
	
	iterator := index newIterator.

	numEntries := 1000.
	entries := OrderedCollection new: numEntries.

	numEntries timesRepeat: [
		| toAdd |
		toAdd := (numEntries * 20) atRandom.
		entries add: toAdd.
		iterator at: toAdd add: (toAdd asByteArrayOfSize: 8) ].

	"check size"
	self assert: iterator size equals: entries asSet size.
	self assert: index size equals: entries asSet size.

	"can we find all the keys we added?"
	entries do: [ :each |
		self assertSoilDuplicate: (iterator at: each) equals: (each asByteArrayOfSize: 8) ].

	"iterate index, all should be in entries"
	iterator do: [ :each |
		self assert: each equals: (each asByteArrayOfSize: 8) ].
	iterator reverseDo: [ :each |
		self assert: each equals: (each asByteArrayOfSize: 8) ]
]

{ #category : #'tests - duplicate keys' }
SoilIndexIteratorTest >> testAddingDuplicateKeyAcrossPages [

	| capacity elements iterator ids page |
	capacity := index headerPage itemCapacity.
	index allowDuplicateKeys.
	iterator := index newIterator.
	ids := OrderedCollection new.
	1 to: capacity do: [ :n |
		ids add: n asDummySoilObjectId.
		iterator at: 1 add: n asDummySoilObjectId ].
	
	page := iterator currentPage.
	
	1 to: capacity do: [ :n |
		ids add: (capacity + n) asDummySoilObjectId.
		iterator at: 1 add: (capacity + n) asDummySoilObjectId ].
	
	self deny: page identicalTo: iterator currentPage.
	self assert: iterator size equals: capacity*2.
	self assert: index size equals: capacity*2.
	
	elements := iterator at: 1.
	"we can ask for all values"
	self assertCollection: elements hasSameElements: ids
]

{ #category : #tests }
SoilIndexIteratorTest >> testAssociationsDo [

	| iterator capacity result |
	iterator := index newIterator.

	"empty case"
	result := OrderedCollection new.
	iterator associationsDo: [ :each | result add: each ].
	self assert: result isEmpty.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].

	result := OrderedCollection new.
	iterator associationsDo: [ :each | result add: each ].

	self assert: result size equals: capacity.
	self assert: result first key equals: 1.
	self assert: result first value equals: (1 asByteArrayOfSize: 8).
	self
		assert: result last value
		equals: (capacity asByteArrayOfSize: 8).
	self assert: result last key equals: capacity
]

{ #category : #tests }
SoilIndexIteratorTest >> testAt [

	| iterator |
	iterator := index newIterator.
	self should: [ iterator at: 1 ] raise: KeyNotFound.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	self assertSoilDuplicate: (iterator at: 1) equals: (1 asByteArrayOfSize: 8).
	self should: [ iterator at: 2 ] raise: KeyNotFound
]

{ #category : #tests }
SoilIndexIteratorTest >> testAtAdd [
	| iterator return |
	
	"at:put: returns last prior value"
	iterator := index newIterator.
	return := iterator at: 1 add: 1 asDummySoilObjectId.
	self assert: return isNil.
	self assertSoilDuplicate: (iterator at: 1) equals: 1 asDummySoilObjectId.
	return := iterator at: 1 add: 2 asDummySoilObjectId.
	uniqueKeys 
		ifTrue: [
			self assert: return equals: 1 asDummySoilObjectId.
			self assert: (iterator at: 1) equals: 2 asDummySoilObjectId]
		ifFalse: [ 
			"with duplicate keys, we do not return the old value"
			self assert: return equals: nil.
			self assertCollection: (iterator at: 1) hasSameElements: {1 asDummySoilObjectId. 2 asDummySoilObjectId}]
]

{ #category : #tests }
SoilIndexIteratorTest >> testAtIfAbsent [
	| iterator return |

	iterator := index newIterator.
	return := iterator at: 1 ifAbsent: [ #missing ].
	self assert: return equals:  #missing
]

{ #category : #tests }
SoilIndexIteratorTest >> testAtIndex [

	| iterator |
	iterator := index newIterator.
	self assert: (iterator atIndex: 1) equals: nil.
	iterator at: 1 add: 1 asDummySoilObjectId.
	self assert: (iterator atIndex: 1) equals: 1 asDummySoilObjectId.
	self assert: (iterator atIndex: 2) equals: nil
]

{ #category : #tests }
SoilIndexIteratorTest >> testDo [

	| iterator capacity result |
	iterator := index newIterator.

	"test empty case"
	result := OrderedCollection new.
	iterator do: [ :each | result add: each ].
	self assert: result size equals: 0.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].

	result := OrderedCollection new.
	iterator do: [ :each | result add: each ].

	self assert: result size equals: capacity.
	self assert: result first equals: (1 asByteArrayOfSize: 8).
	self assert: result last equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testFind [

	| capacity iterator value |
	iterator := index newIterator.

	"empty case"
	value := iterator find: 1.
	self assert: value isNil.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].

	value := iterator find: 222.
	self assertSoilDuplicate: value equals: 222 asDummySoilObjectId.

	value := iterator find: capacity + 1.
	self assert: value isNil
]

{ #category : #tests }
SoilIndexIteratorTest >> testFindAndNext2 [

	| capacity iterator values |
	index uniqueKeys ifFalse: [ self skip ].
	capacity := index firstPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].
	iterator := index newIterator.
	values := iterator
		          find: 222;
		          next: 3.
	self assert: values size equals: 3.
	self assert: values asArray equals: {
			223 asDummySoilObjectId.
			224 asDummySoilObjectId.
			225 asDummySoilObjectId }.
	"test requesting more at the end when the are not enough entries"
	values := iterator
		          find: capacity - 1;
		          next: 3.
	"size is 1"
	self assert: values size equals: 1.
	"and we get the right value"
	self
		assert: values asArray
		equals: { capacity asDummySoilObjectId }
]

{ #category : #tests }
SoilIndexIteratorTest >> testFindIfAbsent [

	| capacity iterator value |
	capacity := index headerPage itemCapacity * 2.
	iterator := index newIterator.

	"empty case"
	value := iterator find: capacity + 1 ifAbsent: [ #notThere ].
	self assert: value equals: #notThere.

	1 to: capacity do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].

	value := iterator find: 222 ifAbsent: [ #notThere ].
	self assertSoilDuplicate: value equals: (222 asByteArrayOfSize: 8).
	value := iterator find: capacity + 1 ifAbsent: [ #notThere ].
	self assert: value equals: #notThere
]

{ #category : #tests }
SoilIndexIteratorTest >> testFindPageFor [

	| capacity iterator value expected |
	iterator := index newIterator.

	"empty case"
	value := iterator findPageFor: 1.
	self assert: value offset equals: 1.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].

	expected := index class == SoilBTree
		            ifTrue: [ 3 ]
		            ifFalse: [ 1 ].
	value := iterator findPageFor: 222.
	self assert: value offset equals: expected.

	expected := index class == SoilBTree
		            ifTrue: [ 4 ]
		            ifFalse: [ 2 ].
	value := iterator findPageFor: capacity + 1.
	self assert: value offset equals: expected
]

{ #category : #tests }
SoilIndexIteratorTest >> testFirst [

	| capacity first |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].
	first := index newIterator first.
	self assert: first equals: 1 asDummySoilObjectId.
	"we get always the first"
	self assert: first equals: 1 asDummySoilObjectId.

	first := index newIterator first: 3.
	self assert: first size equals: 3.
	self assert: first third equals: 3 asDummySoilObjectId.
	self assert: first first equals: 1 asDummySoilObjectId
]

{ #category : #tests }
SoilIndexIteratorTest >> testFirstAssociation [

	| iterator |
	"test empty index"
	iterator := index newIterator.
	self assert: iterator lastAssociation isNil.

	"firstAssociation always returns first"
	iterator := index newIterator.
	iterator at: 1 add: 1 asDummySoilObjectId.
	iterator at: 2 add: 2 asDummySoilObjectId.

	self
		assert: iterator firstAssociation value
		equals: 1 asDummySoilObjectId.
	self
		assert: iterator firstAssociation value
		equals: 1 asDummySoilObjectId
]

{ #category : #tests }
SoilIndexIteratorTest >> testFirstPage [

	| capacity firstPage |
	capacity := index headerPage itemCapacity * 2.

	"check last on empty iterator"
	self
		assert: index newIterator firstPage
		identicalTo: index headerPage.

	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].
	firstPage := index newIterator firstPage.
	self assert: firstPage equals: index headerPage.
	self
		assert: firstPage firstItem value
		equals: 1 asDummySoilObjectId
]

{ #category : #tests }
SoilIndexIteratorTest >> testFirstWithRemovedItem [

	| iterator |
	index uniqueKeys ifFalse: [ self skip ].
	iterator := index newIterator.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator := index newIterator.
	self assert: iterator firstAssociation value equals: nil.

	"first when the first one was removed"
	iterator := index newIterator.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	iterator at: 2 add: (2 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator := index newIterator.
	self
		assert: iterator firstAssociation value
		equals: (2 asByteArrayOfSize: 8).

	"lets remove the two first ones"
	iterator := index newIterator.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	iterator at: 2 add: (2 asByteArrayOfSize: 8).
	iterator at: 3 add: (3 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator removeKey: 2.
	iterator := index newIterator.
	self
		assert: iterator firstAssociation value
		equals: (3 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testGoToNextPage [

	| capacity iterator value nextPage expected |
	iterator := index newIterator.

	"empty case"
	iterator findPageFor: 1.
	value := iterator nextPage.
	self assert: value isNil.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].

	expected := index class == SoilBTree
		            ifTrue: [ 4 ]
		            ifFalse: [ 2 ].
	value := iterator findPageFor: 222.
	nextPage := iterator goToNextPage.
	self assert: nextPage offset equals: expected.
	
	"check that the currentPage was set"
	self assert: iterator currentPage equals: nextPage.

	value := iterator findPageFor: capacity + 1.
	self assert: iterator nextPage isNil
]

{ #category : #tests }
SoilIndexIteratorTest >> testGoToPreviousPage [

	| capacity iterator page toFind priorPage |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList
		          ifTrue: [ 252 ]
		          ifFalse: [ 254 ].
	"the key is indeed the first one in the page"
	self
		assert: (iterator findPageFor: toFind) firstItem key
		equals: toFind.

	iterator := index newIterator.
	priorPage := iterator
		             find: toFind;
		             goToPreviousPage.
	"check that the currentPage was set"
	self assert: iterator currentPage equals: priorPage.

	iterator := index newIterator.
	page := iterator findPageFor: toFind.

	self assert: priorPage next equals: page offset
]

{ #category : #tests }
SoilIndexIteratorTest >> testIsEmpty [

	| iterator |
	iterator := index newIterator.

	self assert: iterator isEmpty.
	index at: 1 add: #something.
	self deny: index isEmpty
]

{ #category : #tests }
SoilIndexIteratorTest >> testLast [

	| capacity last |
	capacity := index headerPage itemCapacity * 2.

	"check last on empty iterator"
	self assert: index newIterator last equals: nil.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	last := index newIterator last.
	self assert: last equals: (capacity asByteArrayOfSize: 8).

	last := index newIterator last: 3.
	self assert: last size equals: 3.
	self assert: last first equals: (capacity - 2 asByteArrayOfSize: 8).
	self assert: last third equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testLastAssociation [

	| iterator |
	"test empty index"
	iterator := index newIterator.
	self assert: iterator lastAssociation isNil.

	"lastAssociation always returns last"
	iterator := index newIterator.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	iterator at: 2 add: (2 asByteArrayOfSize: 8).

	self
		assert: iterator lastAssociation value
		equals: (2 asByteArrayOfSize: 8).
	self
		assert: iterator lastAssociation value
		equals: (2 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testLastPage [

	| capacity lastPage |
	capacity := index headerPage itemCapacity * 2.

	"check last on empty iterator"
	self assert: index newIterator lastPage identicalTo: index headerPage.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	lastPage := index newIterator lastPage.
	self
		assert: lastPage lastItem value
		equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testLastWithRemovedItem [

	| iterator |
	index uniqueKeys ifFalse: [ self skip ].
	iterator := index newIterator.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	iterator removeKey: 1.
	iterator := index newIterator.
	self assert: iterator lastAssociation equals: nil.

	"last when the last one was removed"
	iterator := index newIterator.
	iterator at: 1 add: (1 asByteArrayOfSize: 8).
	iterator at: 2 add: (2 asByteArrayOfSize: 8).
	iterator removeKey: 2.

	iterator := index newIterator.
	self
		assert: iterator lastAssociation value
		equals: (1 asByteArrayOfSize: 8).

	"lets remove the two last ones"
	iterator := index newIterator.
	iterator at: 2 add: (2 asByteArrayOfSize: 8).
	iterator at: 3 add: (3 asByteArrayOfSize: 8).
	iterator removeKey: 3.
	iterator removeKey: 2.
	iterator := index newIterator.
	self
		assert: iterator lastAssociation value
		equals: (1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testNext [

	| capacity iterator value |
	index uniqueKeys ifFalse: [ self skip ].

	"test empty index"
	iterator := index newIterator.
	self assert: iterator next isNil.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	value := iterator
		         find: 222;
		         next.
	self assert: value equals: (223 asByteArrayOfSize: 8).

	iterator := index newIterator.
	value := iterator
		         last;
		         next.

	self assert: value isNil
]

{ #category : #tests }
SoilIndexIteratorTest >> testNextAfter [

	| iterator |
	index uniqueKeys ifFalse: [ self skip ].
	"first empty dict"
	iterator := index newIterator.
	self assert: (iterator nextAfter: 10) equals: nil.

	index at: 10 add: (10 asByteArrayOfSize: 8).
	index at: 20 add: (20 asByteArrayOfSize: 8).

	self assert: (iterator nextAfter: 5) equals: nil.
	self
		assert: (iterator nextAfter: 10)
		equals: (20 asByteArrayOfSize: 8).
	self assert: (iterator nextAfter: 20) equals: nil
]

{ #category : #tests }
SoilIndexIteratorTest >> testNextAssociation [

	| capacity iterator value |
	index uniqueKeys ifFalse: [ self skip ].
	"test empty index"
	iterator := index newIterator.
	self assert: iterator nextAssociation isNil.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	value := iterator
		         find: 222;
		         nextAssociation.

	self assert: value key equals: 223.
	self assert: value value equals: (223 asByteArrayOfSize: 8).

	iterator := index newIterator.
	value := iterator
		         lastAssociation;
		         nextAssociation.

	self assert: value isNil
]

{ #category : #tests }
SoilIndexIteratorTest >> testNextAssociationAfter [

	| iterator |
	index uniqueKeys ifFalse: [ self skip ].
		
	"first empty dict"
	iterator := index newIterator.
	self assert: (iterator nextAssociationAfter: 10) equals: nil.

	index at: 10 add: (10 asByteArrayOfSize: 8).
	index at: 20 add: (20 asByteArrayOfSize: 8).

	self assert: (iterator nextAssociationAfter: 5) equals: nil.
	self
		assert: (iterator nextAssociationAfter: 10) value
		equals: (20 asByteArrayOfSize: 8).
	self assert: (iterator nextAssociationAfter: 10) key equals: 20.
	self assert: (iterator nextAssociationAfter: 20) equals: nil
]

{ #category : #tests }
SoilIndexIteratorTest >> testNextCloseTo [

	| iterator |
	"first empty dict"
	iterator := index newIterator.
	self assert: (iterator nextCloseTo: 5) equals: nil.

	iterator := index newIterator.
	index at: 10 add: (10 asByteArrayOfSize: 8).
	index at: 20 add: (20 asByteArrayOfSize: 8).


	self
		assertSoilDuplicate: (iterator nextCloseTo: 5)
		equals: (10 asByteArrayOfSize: 8).
	self
		assertSoilDuplicate: (iterator nextCloseTo: 10)
		equals: (10 asByteArrayOfSize: 8).
	self
		assertSoilDuplicate: (iterator nextCloseTo: 11)
		equals: (20 asByteArrayOfSize: 8).
	self
		assertSoilDuplicate: (iterator nextCloseTo: 15)
		equals: (20 asByteArrayOfSize: 8).
	self
		assertSoilDuplicate: (iterator nextCloseTo: 20)
		equals: (20 asByteArrayOfSize: 8).
	"this is a bit odd, when looking with larger values we get the last one"
	self
		assertSoilDuplicate: (iterator nextCloseTo: 100)
		equals: (20 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testNextKeyCloseTo [

	| iterator |
	"first empty dict"
	iterator := index newIterator.
	self assert: (iterator nextKeyCloseTo: 5) equals: nil.

	iterator := index newIterator.
	index at: 10 add: (10 asByteArrayOfSize: 8).
	index at: 20 add: (20 asByteArrayOfSize: 8).


	self assert: (iterator nextKeyCloseTo: 5) equals: 10.
	self assert: (iterator nextKeyCloseTo: 10) equals: 10.
	self assert: (iterator nextKeyCloseTo: 11) equals: 20.
	self assert: (iterator nextKeyCloseTo: 15) equals: 20.
	self assert: (iterator nextKeyCloseTo: 20) equals: 20.
	"this is a bit odd, when looking with larger values we get the last one"
	self assert: (iterator nextKeyCloseTo: 100) equals: 20
]

{ #category : #tests }
SoilIndexIteratorTest >> testNextPage [

	| capacity iterator value expected |
	iterator := index newIterator.

	"empty case"
	iterator findPageFor: 1.
	value := iterator nextPage.
	self assert: value isNil.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].

	expected := index class == SoilBTree
		            ifTrue: [ 4 ]
		            ifFalse: [ 2 ].
	value := iterator findPageFor: 222.
	self assert: iterator nextPage offset equals: expected.

	value := iterator findPageFor: capacity + 1.
	self assert: iterator nextPage isNil
]

{ #category : #tests }
SoilIndexIteratorTest >> testPrevious [

	| capacity iterator value toFind |
	index uniqueKeys ifFalse: [ self skip ].

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n  asDummySoilObjectId ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList
		          ifTrue: [ 252 ]
		          ifFalse: [ 127 ].
	"the key is indeed the first one in the page"
	self
		assert: (iterator findPageFor: toFind) firstItem key
		equals: toFind.

	iterator := index newIterator.
	value := iterator
		         find: toFind;
		         previous.
	self assert: value equals: (toFind - 1) asDummySoilObjectId
]

{ #category : #tests }
SoilIndexIteratorTest >> testPrevious5 [

	| capacity iterator result |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	result := iterator
		          find: 6;
		          previous: 5.
	self assert: result size equals: 5
]

{ #category : #tests }
SoilIndexIteratorTest >> testPreviousAssociation [

	| capacity iterator value toFind |
	index uniqueKeys ifFalse: [ self skip ].
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.

	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList
		          ifTrue: [ 252 ]
		          ifFalse: [ 254 ].
	"the key is indeed the first one in the page"
	self
		assert: (iterator findPageFor: toFind) firstItem key
		equals: toFind.

	iterator := index newIterator.
	value := iterator
		         find: toFind;
		         previousAssociation.
	self assert: value value equals: (toFind - 1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testPreviousAssociationFirstPage [

	| capacity iterator value |
	index uniqueKeys ifFalse: [ self skip ].
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].

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
	self assert: value value equals: (capacity - 1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testPreviousAssociationNonBoundary [
	"check previousAssociation where we have to *not* cross a page boundary"

	| capacity iterator value toFind |
	index uniqueKeys ifFalse: [ self skip ].
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.

	"select a key where we do not have to cross over to another page"
	toFind := index class == SoilSkipList
		          ifTrue: [ 255 ]
		          ifFalse: [ 256 ].
	"the key is indeed not the first one in the page"
	self
		deny: (iterator findPageFor: toFind) firstItem key
		equals: toFind.

	iterator := index newIterator.
	value := iterator
		         find: toFind;
		         previousAssociation.
	self assert: value value equals: (toFind - 1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilIndexIteratorTest >> testPreviousPage [

	| capacity iterator page toFind priorPage |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"select a key where we have to cross over to another page"
	toFind := index class == SoilSkipList
		          ifTrue: [ 252 ]
		          ifFalse: [ 254 ].
	"the key is indeed the first one in the page"
	self
		assert: (iterator findPageFor: toFind) firstItem key
		equals: toFind.

	iterator := index newIterator.
	priorPage := iterator
		             find: toFind;
		             previousPage.

	iterator := index newIterator.
	page := iterator findPageFor: toFind.

	self assert: priorPage next equals: page offset
]

{ #category : #tests }
SoilIndexIteratorTest >> testPreviousPageFirstPage [

	| capacity iterator |
	"fisrt check on empty"
	iterator := index newIterator.
	iterator firstPage. "set iterator currentPage to first page"
	self assert: iterator previousPage equals: nil.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	iterator firstPage. "set iterator currentPage to first page"
	self assert: iterator previousPage equals: nil
]

{ #category : #tests }
SoilIndexIteratorTest >> testRemoveKey [

	| capacity iterator result |
	capacity := index headerPage itemCapacity * 2.

	"test empty iterator"
	iterator := index newIterator.
	"removing non-existing keys raises KeyNotFound error"
	self should: [ iterator removeKey: 1 ] raise: KeyNotFound.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"removing non-existing keys raises KeyNotFound error"
	self should: [ iterator removeKey: capacity + 1 ] raise: KeyNotFound.
	result := iterator removeKey: 1.
	self assertSoilDuplicate: result equals: (1 asByteArrayOfSize: 8).
	result := iterator removeKey: capacity.
	self assertSoilDuplicate: result equals: (capacity asByteArrayOfSize: 8).
	"removing the key again raises KeyNotFound, too"
	self should: [ iterator removeKey: capacity ] raise: KeyNotFound
]

{ #category : #'tests - duplicate keys' }
SoilIndexIteratorTest >> testRemoveKeyDuplicate [

	| capacity iterator result |
	index allowDuplicateKeys.
	capacity := index headerPage itemCapacity * 2.

	"test empty iterator"
	iterator := index newIterator.
	"removing non-existing keys raises KeyNotFound error"
	self should: [ iterator removeKey: 1 ] raise: KeyNotFound.

	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].
	iterator := index newIterator.
	"removing non-existing keys raises KeyNotFound error"
	self should: [ iterator removeKey: capacity + 1 ] raise: KeyNotFound.
	"we add a second value for 1"
	index at: 1 add: 2 asDummySoilObjectId.
	self assertCollection: (index at: 1) hasSameElements: {1 asDummySoilObjectId. 2 asDummySoilObjectId}.
	result := iterator removeKey: 1.
	self assertCollection: result hasSameElements: {1 asDummySoilObjectId. 2 asDummySoilObjectId}.
	
	"removing the key again raises KeyNotFound, too"
	self should: [ iterator removeKey: 1 ] raise: KeyNotFound
]

{ #category : #tests }
SoilIndexIteratorTest >> testRemoveKeyIfAbsent [

	| capacity iterator result |
	capacity := index headerPage itemCapacity * 2.

	"test empty iterator"
	iterator := index newIterator.
	"removing non-existing keys raises KeyNotFound error"
	result := iterator removeKey: 1 ifAbsent: [ #hello ].
	self assert: result equals: #hello.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	iterator := index newIterator.
	"removing non-existing keys executes absent block"
	result := iterator removeKey: capacity + 1 ifAbsent: #hello.
	self assert: result equals: #hello.
	result := iterator removeKey: 1 ifAbsent: [ #hello ].
	self assertSoilDuplicate: result equals: (1 asByteArrayOfSize: 8).
	result := iterator removeKey: capacity ifAbsent: [ #hello ].
	self assertSoilDuplicate: result equals: (capacity asByteArrayOfSize: 8).
	"removing the key again executes absent block"
	result := iterator removeKey: capacity ifAbsent: [ #hello ].
	self assert: result equals: #hello
]

{ #category : #tests }
SoilIndexIteratorTest >> testReverseDo [

	| capacity result |
	"empty case"
	result := OrderedCollection new.
	index newIterator reverseDo: [ :each | result add: each ].
	self assert: result size equals: 0.

	result := OrderedCollection new.
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n | index at: n add: n asDummySoilObjectId ].

	result := OrderedCollection new.
	index newIterator reverseDo: [ :each | result add: each ].

	self assert: result size equals: capacity.
	self assert: result first equals: capacity asDummySoilObjectId.
	self assert: result last equals: 1 asDummySoilObjectId
]

{ #category : #tests }
SoilIndexIteratorTest >> testSize [

	| iterator capacity |
	iterator := index newIterator.
	self assert: iterator size equals: 0.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
	iterator at: n add: n asDummySoilObjectId ].

	self assert: iterator size equals: capacity
]

{ #category : #tests }
SoilIndexIteratorTest >> testValues [

	| iterator capacity |
	iterator := index newIterator.
	"empty case"
	self assert: iterator values isEmpty.

	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
	iterator at: n add: n asDummySoilObjectId ].

	self assert: iterator values size equals: capacity.
	self assert: iterator values first equals: 1 asDummySoilObjectId.
	self assert: iterator values last equals: capacity asDummySoilObjectId
]

{ #category : #accessing }
SoilIndexIteratorTest >> uniqueKeys [

	^ uniqueKeys
]

{ #category : #accessing }
SoilIndexIteratorTest >> uniqueKeys: anObject [

	uniqueKeys := anObject
]
