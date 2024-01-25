Class {
	#name : #SoilSkipListTest,
	#superclass : #TestCase,
	#instVars : [
		'index'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
SoilSkipListTest >> setUp [ 
	super setUp.
	index := SoilSkipList new 
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
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflowAppending [
	
	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: 254.
	self assert: page items last key asByteArray equals: #[ 254 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflowReload [
	
	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: 254.
	self assert: page items last key asByteArray equals: #[ 254 ].
	
	"write it and then read it back with a new SoilSkipList"
	index writePages.
	index close.
	index := SoilSkipList new 
		path: 'sunit-skiplist';
		initializeFilesystem;
		open.
	"we should be able to do a lookup"
	self assert: ((index at: capacity) asByteArrayOfSize: 8) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflowSplitting [
	
	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: capacity - 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 126.
	self assert: page items first key equals: 255.
	self assert: page items last key asByteArray equals: #[ 1 249 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetween [
	
	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: (capacity / 2) floor put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 1.
	page := index pageAt: 1.
	self assert: page numberOfItems equals: 253.
	self assert: (page items at: (capacity / 2) floor) key equals: 126
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverflowing [
	
	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: 32 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 126.
	self assert: (page items first) key equals: 255.
	self assert: (page items last) key asByteArray equals: #[ 1 249 ].
	index writePages 
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverwriting [
	
	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: 31 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 1.
	page := index pageAt: 1.
	self assert: page numberOfItems equals: 253.
	self assert: (page items at: 16) value equals: #[ 8 7 6 5 4 3 2 1 ] 
]

{ #category : #tests }
SoilSkipListTest >> testAddLastFitting [
	
	| page |
	1 to: 61 do: [ :n | 
		index at: (n asString asIndexKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: (63 asString asIndexKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 1.
	page := index pageAt: 1.
	self assert: page numberOfItems equals: 62.
	self assert: page items last key asByteArray equals: #[ 54 51 ]
]

{ #category : #tests }
SoilSkipListTest >> testAt [
	
	| capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 2.
	
	"we should be able to find the key that is on the second page"
	self assert: (index at: capacity + 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ index at: capacity + 2  ] raise: KeyNotFound
]

{ #category : #tests }
SoilSkipListTest >> testAtIndex [
	| value |
	1 to: 200 do: [ :n |
		index at: n put: n asSoilObjectId ].
	value := index atIndex: 133. 
	self assert: (value isSameObjectId: 133 asSoilObjectId) 
]

{ #category : #tests }
SoilSkipListTest >> testCreation [
	self assert: index pages size equals: 1
]

{ #category : #tests }
SoilSkipListTest >> testDo [
	
	| capacity col |
	capacity := index firstPage itemCapacity.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 2.
	col := OrderedCollection new.
	index do: [ :item | col add: item ].
	self assert: col first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: col size equals: capacity + 1
]

{ #category : #tests }
SoilSkipListTest >> testFindKey [
	| value |
	1 to: 200 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	value := index find: 133. 
	self assert: value equals: #[ 1 2 3 4 5 6 7 8 ]
]

{ #category : #tests }
SoilSkipListTest >> testFindKeyReverse [
	| value |
	200 to: 1 by: -1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	"skipList writePages."
	value := index find: 133. 
	self assert: value equals: #[ 1 2 3 4 5 6 7 8 ]
]

{ #category : #tests }
SoilSkipListTest >> testFirst [
	
	| capacity |
	capacity := index firstPage itemCapacity * 2.

	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 3.
	self assert: index first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: (index first: 2) second equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
SoilSkipListTest >> testFirstArgLargerThenSize [

	1 to: 4 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 1.
	self assert: (index first: 5) size equals: 4
]

{ #category : #tests }
SoilSkipListTest >> testIsEmpty [
	self assert: index isEmpty.
	index at: 1 put: #[1 2].
	self deny: index isEmpty
]

{ #category : #tests }
SoilSkipListTest >> testIteratorFindAndNext [
	
	| capacity iterator value |
	capacity := index firstPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 2.
	iterator := index newIterator.
	value := iterator
		find: 222;
		next.
	self assert: value equals: (223 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testIteratorFindAndNext2 [
	
	| capacity iterator values |
	capacity := index firstPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 2.
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
SoilSkipListTest >> testIteratorFirstWithSingleRemovedItem [ 
	| iterator |
	iterator := index newIterator.
	iterator at: #foo put: #bar.
	iterator removeKey: #foo.
	self assert: iterator firstAssociation equals: nil
]

{ #category : #tests }
SoilSkipListTest >> testIteratorLastWithSingleRemovedItem [ 
	| iterator |
	iterator := index newIterator.
	iterator at: #foo put: #bar.
	iterator removeKey: #foo.
	self assert: iterator lastAssociation equals: nil
]

{ #category : #tests }
SoilSkipListTest >> testLast [
	
	| capacity |
	capacity := index firstPage itemCapacity * 2.

	1 to: capacity - 1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 2.
	self assert: index last equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilSkipListTest >> testLastPage [
	
	| capacity lastItem |
	index maxLevel: 8.
	capacity := index firstPage itemCapacity * 100.

	1 to: capacity - 1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 100.
	self assert: index lastPage index equals: 100.
	self assert: index lastPage isLastPage.
	lastItem := index lastPage itemAt: capacity ifAbsent: [nil].
	self assert: lastItem value equals: #[ 8 7 6 5 4 3 2 1 ].
]

{ #category : #tests }
SoilSkipListTest >> testMorePages [
	1 to: 512 do: [ :n |
		index at: (n asString asIndexKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	index writePages.
	self assert: index pages size equals: 3
]

{ #category : #tests }
SoilSkipListTest >> testOverflowCopyOnWriteAppending [
	
	| page capacity copyOnWrite |
	copyOnWrite := index asCopyOnWrite.
	capacity := copyOnWrite firstPage itemCapacity.
	1 to: capacity do: [ :n | 
		copyOnWrite at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: copyOnWrite pages size equals: 1.
	copyOnWrite at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: copyOnWrite pages size equals: 2.
	page := copyOnWrite pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: 254.
	self assert: page items last key asByteArray equals: #[ 254 ]
]

{ #category : #tests }
SoilSkipListTest >> testOverflowCopyOnWriteSplitting [
	
	| page capacity copyOnWrite |
	copyOnWrite := index asCopyOnWrite.
	capacity := copyOnWrite firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		copyOnWrite at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: copyOnWrite pages size equals: 1.
	copyOnWrite at: 2 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: copyOnWrite pages size equals: 2.
	page := copyOnWrite pageAt: 2.
	self assert: page numberOfItems equals: 126.
	self assert: page items first key equals: 255.
	self assert: page items last key asByteArray equals: #[ 1 249 ]
]

{ #category : #tests }
SoilSkipListTest >> testPageAddFirst [
	
	| page |
	index at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	index writePages.
	self assert: index pages size equals: 1.
	page := index firstPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (#foo asIndexKeyOfSize: 8) asInteger
]

{ #category : #tests }
SoilSkipListTest >> testReIndexing [
	
	| capacity fileSizeBefore |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	index flush.
	fileSizeBefore := index path size.
	index reIndex.
	self assert: index headerPage lastPageIndex equals: 2.
	self assert: (index pageAt: 2) items size equals: 1.
	"self assert: index path size equals: fileSizeBefore"
]

{ #category : #tests }
SoilSkipListTest >> testReIndexingWithCleaning [
	
	| capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	index flush.
	1 to: capacity do: [ :n | 
		index at: n  put: SoilObjectId removed ].
	
	index newReIndexer cleanRemoved run.
	self assert: index headerPage lastPageIndex equals: 1.
	self assert: (index pageAt: 1) items size equals: 1.
	self assert: (index at: capacity + 1) asByteArray equals: #[ 1 2 3 4 5 6 7 8 ].

]

{ #category : #tests }
SoilSkipListTest >> testRemoveKey [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	index removeKey: 20.
	
	self assert: (index at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ index at: 20  ] raise: KeyNotFound.
	index at: 20 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 20) equals: #[ 1 2 3 4 5 6 7 8 ].
	
	self should: [ index removeKey: capacity + 1 ] raise: KeyNotFound
]

{ #category : #tests }
SoilSkipListTest >> testSize [
	
	| capacity |
	capacity := index firstPage itemCapacity.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 2.
	self assert: index size equals: capacity + 1.
]

{ #category : #tests }
SoilSkipListTest >> testSplitLastPage [	
	| headerCapacity itemCapacity |
	"fill the header page"
	headerCapacity := index headerPage itemCapacity.
	1 to: headerCapacity do: [ :n |
		index at: n put: n ].
	self assert: index pages size equals:  1.
	"trigger page split and check it happened"
	index at: headerCapacity + 1 put: 0.
	self assert: index pages size equals:  2.
	"fill second page til the end"
	itemCapacity := (index pageAt: 2) itemCapacity.
	headerCapacity + 2 to: headerCapacity + itemCapacity do: [ :n |
		index at: n put: n ].
	self assert: index pages size equals:  2.
	"another page split which should be appending"
	index at: 3000 put: 3000.
	
]
