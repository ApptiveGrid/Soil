Class {
	#name : #SoilSkipListTest,
	#superclass : #TestCase,
	#instVars : [
		'skipList'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilSkipListTest >> setUp [ 
	super setUp.
	skipList := SoilSkipList new 
		path: 'sunit-skiplist';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: 4;
		keySize: 8;
		valueSize: 8
]

{ #category : #running }
SoilSkipListTest >> tearDown [ 
	skipList ifNotNil: [ 
		skipList close ].
	super tearDown
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflow [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		skipList at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 128.
	self assert: page items first key equals: 129.
	self assert: page items last key asByteArray equals: #[ 1 0 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflowReload [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		skipList at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 128.
	self assert: page items first key equals: 129.
	self assert: page items last key asByteArray equals: #[ 1 0 ].
	
	"write it and then read it back with a new SoilSkipList"
	skipList writePages.
	skipList close.
	skipList := SoilSkipList new 
		path: 'sunit-skiplist';
		initializeFilesystem;
		open.
	"we should be able to do a lookup"
	self assert: ((skipList at: capacity) asByteArrayOfSize: 8) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetween [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity.
	1 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (capacity / 2) floor put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 255.
	self assert: (page items at: (capacity / 2) floor) key equals: 127
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverflowing [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: 32 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 127.
	self assert: (page items first) key equals: 257.
	self assert: (page items last) key asByteArray equals: #[ 1  253 ].
	skipList writePages 
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverwriting [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: 31 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 255.
	self assert: (page items at: 16) value equals: #[ 8 7 6 5 4 3 2 1 ] 
]

{ #category : #tests }
SoilSkipListTest >> testAddLastFitting [
	
	| page |
	1 to: 61 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (63 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 62.
	self assert: page items last key asByteArray equals: #[ 54 51 ]
]

{ #category : #tests }
SoilSkipListTest >> testAt [
	
	| capacity |
	capacity := skipList firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		skipList at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	
	"we should be able to find the key that is on the second page"
	self assert: (skipList at: capacity + 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ skipList at: capacity + 2  ] raise: KeyNotFound
]

{ #category : #tests }
SoilSkipListTest >> testAtIndex [
	| value |
	1 to: 200 do: [ :n |
		skipList at: n put: n asSoilObjectId ].
	value := skipList atIndex: 133. 
	self assert: (value isSameObjectId: 133 asSoilObjectId) 
]

{ #category : #tests }
SoilSkipListTest >> testCreation [
	self assert: skipList pages size equals: 1
]

{ #category : #tests }
SoilSkipListTest >> testDo [
	
	| capacity col |
	capacity := skipList firstPage itemCapacity.
	skipList at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	col := OrderedCollection new.
	skipList do: [ :item | col add: item ].
	self assert: col first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: col size equals: capacity + 1
]

{ #category : #tests }
SoilSkipListTest >> testFindKey [
	| value |
	1 to: 200 do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	value := skipList find: 133. 
	self assert: value equals: #[ 1 2 3 4 5 6 7 8 ]
]

{ #category : #tests }
SoilSkipListTest >> testFindKeyReverse [
	| value |
	200 to: 1 by: -1 do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	"skipList writePages."
	value := skipList find: 133. 
	self assert: value equals: #[ 1 2 3 4 5 6 7 8 ]
]

{ #category : #tests }
SoilSkipListTest >> testFirst [
	
	| capacity |
	capacity := skipList firstPage itemCapacity * 2.

	2 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 3.
	self assert: skipList first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: (skipList first: 2) second equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilSkipListTest >> testIsEmpty [
	self assert: skipList isEmpty.
	skipList at: 1 put: #[1 2].
	self deny: skipList isEmpty
]

{ #category : #tests }
SoilSkipListTest >> testIteratorFindAndNext [
	
	| capacity iterator value |
	capacity := skipList firstPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		skipList at: n put: (n asByteArrayOfSize: 8) ].
	self assert: skipList pages size equals: 3.
	iterator := skipList newIterator.
	value := iterator
		find: 222;
		next.
	self assert: value equals: (223 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testLast [
	
	| capacity |
	capacity := skipList firstPage itemCapacity * 2.

	1 to: capacity - 1 do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 3.
	self assert: skipList last equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilSkipListTest >> testMorePages [
	1 to: 512 do: [ :n |
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList writePages.
	self assert: skipList pages size equals: 4
]

{ #category : #tests }
SoilSkipListTest >> testPageAddFirst [
	
	| page |
	skipList at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	skipList writePages.
	self assert: skipList pages size equals: 1.
	page := skipList firstPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (#foo asSkipListKeyOfSize: 8) asInteger
]

{ #category : #tests }
SoilSkipListTest >> testRemoveKey [

	| capacity |
	capacity := skipList headerPage itemCapacity.
	1 to: capacity do: [ :n | skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	skipList removeKey: 20.
	
	self assert: (skipList at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (skipList at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ skipList at: 20  ] raise: KeyNotFound.
	skipList at: 20 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (skipList at: 20) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilSkipListTest >> testSize [
	
	| capacity |
	capacity := skipList firstPage itemCapacity.
	skipList at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	self assert: skipList size equals: capacity + 1.
]
