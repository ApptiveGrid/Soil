Class {
	#name : 'SoilBTreeTest',
	#superclass : 'TestCase',
	#instVars : [
		'index'
	],
	#category : 'Soil-Core-Tests',
	#package : 'Soil-Core-Tests'
}

{ #category : 'running' }
SoilBTreeTest >> setUp [ 
	super setUp.
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 8;
		valueSize: 8
]

{ #category : 'running' }
SoilBTreeTest >> tearDown [ 
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : 'tests' }
SoilBTreeTest >> testAddFirstOverflow [

	| page capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 127.
	"if we add a page, the current one is split and half is moved there"
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 3.
	page := index pageAt: 3.
	self assert: page numberOfItems equals: 128.
	self assert: page items first key equals: 128.
	self assert: page items last key asByteArray equals: #[ 255 ].
	"check that the next pointer is correct after split"
	self assert: (index pageAt:((index headerPage) next)) identicalTo: (index pageAt: 3)
]

{ #category : 'tests' }
SoilBTreeTest >> testAddRandom [
	| numEntries entries |
	"just some random addind and checking that we can find it. tree is configured to create lots of pages"
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512;
		valueSize: 512.
	
	numEntries := 20.
	entries := Set new: numEntries.
	
	
	numEntries timesRepeat: [ | toAdd |
		toAdd := (numEntries*20) atRandom.
		entries add: toAdd.
		index at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
]

{ #category : 'tests' }
SoilBTreeTest >> testAddSecondOverflow [

	| page capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 127.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n | index at: capacity + n put: #[ 1 2 3 4 5 6 7 8 ]].
	self assert: index pages size equals: 4.
	page := index pageAt: 4.
	self assert: page numberOfItems equals: 253.
	self assert: page items first key equals: 256.
	"check that the next pointer is correct after split"
	self assert: ((index headerPage nextPageIn: index) nextPageIn: index) identicalTo: (index pageAt: 4).
	index writePages.
]

{ #category : 'tests' }
SoilBTreeTest >> testAddSecondOverflowReload [
	| page capacity |

	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 127.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n | index at: capacity + n put: #[ 1 2 3 4 5 6 7 8 ]].
	self assert: index pages size equals: 4.
	page := index pageAt: 4.
	self assert: page numberOfItems equals: 253.
	self assert: page items first key equals: 256.
	"check that the next pointer is correct after split"
	self assert: ((index headerPage nextPageIn: index) nextPageIn: index) identicalTo: (index pageAt: 4).

	index writePages.
	index close.
	index := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open. 
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : 'tests' }
SoilBTreeTest >> testAt [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 127.
	"if we add a page, the current one is split and half is moved there"
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 3.
	
	self assert: (index at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity + 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ index at: capacity + 2  ] raise: KeyNotFound
]

{ #category : 'tests' }
SoilBTreeTest >> testAtSecondOverflow [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity*2 do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 4.
	self assert: (index pageAt: 1) numberOfItems equals: 127.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n | index at: capacity + n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 4.
	
	self assert: (index at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity + 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity + capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ index at: capacity * 2 + 1  ] raise: KeyNotFound
]

{ #category : 'tests' }
SoilBTreeTest >> testCreation [
	"we alwaus create one data page and the root index"
	self assert: index pages size equals: 2.
	"both pages start as dirty"
	self assert: (index pages at: 1) isDirty.
	self assert: (index pages at: 2) isDirty
]

{ #category : 'tests' }
SoilBTreeTest >> testFirst [
	
	| capacity |
	capacity := index headerPage itemCapacity * 2.

	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 4.
	self assert: index first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: (index first: 2) second equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : 'tests' }
SoilBTreeTest >> testIndexRewriting [
	
	| capacity fileSizeBefore |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	index flush.
	self assert: index headerPage lastPageIndex equals: 3.
	self assert: (index pageAt: 3) items size equals: 128.
	self assert: (index pageAt: 1) items size equals: 127.
	fileSizeBefore := index path size.
	index newPluggableRewriter rewrite.
	self assert: index headerPage lastPageIndex equals: 3.
	self assert: (index pageAt: 3) items size equals: 128.
	self assert: (index pageAt: 1) items size equals: 127.
	
	self assert: index path size equals: fileSizeBefore

]

{ #category : 'tests' }
SoilBTreeTest >> testIndexRewritingWithCleaning [
	
	| capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n | 
		index at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	index flush.
	1 to: capacity do: [ :n | 
		index at: n  put: SoilObjectId removed ].
	
	index newPluggableRewriter cleanRemoved run.
	self assert: index headerPage lastPageIndex equals: 2.
	self assert: (index pageAt: 1) items size equals: 1.
	self assert: (index at: capacity + 1) asByteArray equals: #[ 1 2 3 4 5 6 7 8 ].

]

{ #category : 'tests' }
SoilBTreeTest >> testIsEmpty [
	self assert: index isEmpty.
	index at: 1 put: #[1 2].
	self deny: index isEmpty
]

{ #category : 'tests' }
SoilBTreeTest >> testIteratorFindAndNext [
	
	| capacity iterator value |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
	iterator := index newIterator.
	value := iterator
		find: 222;
		next.
	self assert: value equals: (223 asByteArrayOfSize: 8)
]

{ #category : 'tests' }
SoilBTreeTest >> testIteratorFindAndNext2 [
	
	| capacity iterator values |
	capacity := index headerPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		index at: n put: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
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

{ #category : 'tests' }
SoilBTreeTest >> testIteratorFirst [
	
	| capacity first |
	capacity := index headerPage itemCapacity * 2.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: index pages size equals: 4.
	first := index newIterator first.
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : 'tests' }
SoilBTreeTest >> testLast [
	
	| capacity |
	capacity := index headerPage itemCapacity * 2.

	1 to: capacity - 1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 4.
	self assert: index last equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : 'tests' }
SoilBTreeTest >> testLastPage [
	
	| capacity lastItem |
	index maxLevel: 8.
	capacity := index firstPage itemCapacity * 100.

	1 to: capacity - 1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 199.
	self assert: index lastPage index equals: 199.
	self assert: index lastPage isLastPage.
	lastItem := index lastPage itemAt: capacity ifAbsent: [nil].
	self assert: lastItem value equals: #[ 8 7 6 5 4 3 2 1 ].
]

{ #category : 'tests' }
SoilBTreeTest >> testOverflowCopyOnWriteSplitting [
	
	| page capacity copyOnWrite |
	copyOnWrite := index asCopyOnWrite.
	capacity := copyOnWrite headerPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n | 
		copyOnWrite at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: copyOnWrite pages size equals: 3.

	page := copyOnWrite pageAt: 3.
	self assert: page numberOfItems equals: 127.
	self assert: page items first key equals: 255.
	self assert: page items last key asByteArray equals: #[1 251]
]

{ #category : 'tests' }
SoilBTreeTest >> testPageAddFirst [
	
	| page indexPage |
	index at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	index writePages.
	self assert: index pages size equals: 2.
	page := index headerPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (index indexKey: #foo).
	"the index page was updated"
	indexPage := index rootPage.
	"Index has been updated"
	self assert: indexPage items size equals: 1
	
	
]

{ #category : 'tests' }
SoilBTreeTest >> testPageAddFirstAndLoad [
	
	| page indexPage |
	index at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	index writePages.
	self assert: index pages size equals: 2.
	page := index headerPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (index indexKey: #foo).
	"the index page was updated"
	indexPage := index rootPage.
	"Index has been updated"
	self assert: indexPage items size equals: 1.

	"load back"
	
	index close.
	index := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open.
	
	self assert: page items first key equals:(index indexKey: #foo).
	"load succeeds"
	self assert: (index at: #foo) equals: #[ 1 2 3 4 5 6 7 8 ].

]

{ #category : 'tests' }
SoilBTreeTest >> testRemoveKey [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	index removeKey: 20.
	
	self assert: (index at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ index at: 20 ] raise: KeyNotFound.
	self should: [ index removeKey: 20  ] raise: KeyNotFound.
]

{ #category : 'tests' }
SoilBTreeTest >> testSize [
	
	| capacity |
	capacity := index headerPage itemCapacity.
	index at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 3.
	self assert: index size equals: capacity + 1.
]

{ #category : 'tests' }
SoilBTreeTest >> testSplitIndexPage [
	| entries |
	"this test leads to a split of a non-root index page"
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512;
		valueSize: 512.
	
	entries :=  #(104 247 56 281 61 286 66 337 308 1 400 272 347 335 45 62 207 7 123 140).
	
	
	entries do: [:toAdd |
		index at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
]

{ #category : 'tests' }
SoilBTreeTest >> testSplitIndexPageReleoad [
	| entries |
	"this test leads to a split of a non-root index page"
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512 ;
		valueSize: 512.
	
	entries :=  #(104 247 56 281 61 286 66 337 308 1 400 272 347 335 45 62 207 7 123 140).
	
	
	entries do: [:toAdd |
		index at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
	
	"write and reload"
	index writePages.
	index close.
	index := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem;
		open. 
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: (#[ 1 2 3 4 5 6 7 8 ] asByteArrayOfSize: 512)].
]
