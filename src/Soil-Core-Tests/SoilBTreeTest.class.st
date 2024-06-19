Class {
	#name : #SoilBTreeTest,
	#superclass : #TestCase,
	#instVars : [
		'index'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #running }
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

{ #category : #running }
SoilBTreeTest >> tearDown [ 
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : #tests }
SoilBTreeTest >> testAdd2 [
	| entries |
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 1016;
		valueSize: 8.
	
	entries :=  #(6 16 26 36 46 ).
	
	index at: 6  put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 6) equals: #[ 1 2 3 4 5 6 7 8 ].
	
	index at: 16  put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 6) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 16) equals: #[ 1 2 3 4 5 6 7 8 ].
	
	"We have two pages"
	self assert: index pages size equals: 2.
	"one index, one data"
	self assert: index indexPages size equals: 1.
	self assert: index dataPages size equals: 1.
	"index page has just the default entry for the smalles possible key"
	self assert: (index rootPage items collect: #key) size equals: 1.
	self assert: (index rootPage items collect: #key) first equals: 0. 
	
	
	"with adding 26, we have to split the data page"
	index at: 26  put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: index pages size equals: 3.
	self assert: index indexPages size equals: 1.
	self assert: index dataPages size equals: 2.
	
	self assert: (index at: 6) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 16) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 26) equals: #[ 1 2 3 4 5 6 7 8 ].
	
	"index page has two entries: 0 and 16"
	self assert: (index rootPage items collect: #key) size equals: 2.
	self assert: (index rootPage items collect: #key) first equals: 0. 
	self assert: (index rootPage items collect: #key) second equals: 16. 
	
	"adding 36 causes overlow in data node, have to add the new page to index"
	index at: 36  put: #[ 1 2 3 4 5 6 7 8 ].
	
	self assert: index pages size equals: 4.
	self assert: index indexPages size equals: 1.
	self assert: index dataPages size equals: 3.
	
	self assert: (index at: 6) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 16) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 26) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 36) equals: #[ 1 2 3 4 5 6 7 8 ].
	
	"index page has trhee entries: 0 and 16 and 26"
	self assert: (index rootPage items collect: #key) size equals: 3.
	self assert: (index rootPage items collect: #key) first equals: 0. 
	self assert: (index rootPage items collect: #key) second equals: 16. 
	self assert: (index rootPage items collect: #key) third equals: 26. 
	
	"adding 46 causes overlow in data node and the index node"
	index at: 46  put: #[ 1 2 3 4 5 6 7 8 ].
	
	self assert: index pages size equals: 7.
	self assert: index indexPages size equals: 3.
	self assert: index dataPages size equals: 4.
	
	self assert: (index at: 6) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 16) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 26) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 36) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: 46) equals: #[ 1 2 3 4 5 6 7 8 ].
	
	"index page has trhee entries: 0 and 16 and 26"

	self assert: (index rootPage items collect: #key) first equals: 0. 
	self assert: (index rootPage items collect: #key) second equals: 26. 

	self assert: index indexPages second items second key equals: 16.
	self assert: index indexPages first items second key equals: 36.
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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
	self assert: page numberOfItems equals: 254.
	self assert: page items first key equals: 255.
	"check that the next pointer is correct after split"
	self assert: ((index headerPage nextPageIn: index) nextPageIn: index) identicalTo: (index pageAt: 4).
	index writePages.
]

{ #category : #tests }
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
	self assert: page numberOfItems equals: 254.
	self assert: page items first key equals: 255.
	"check that the next pointer is correct after split"
	self assert: ((index headerPage nextPageIn: index) nextPageIn: index) identicalTo: (index pageAt: 4).

	index writePages.
	index close.
	index := SoilBTree new 
		path: 'sunit-btree';
		initializeFilesystem.
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
SoilBTreeTest >> testCreation [
	"we alwaus create one data page and the root index"
	self assert: index pages size equals: 2.
	"both pages start as dirty"
	self assert: (index pages at: 1) isDirty.
	self assert: (index pages at: 2) isDirty
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
SoilBTreeTest >> testIsEmpty [
	self assert: index isEmpty.
	index at: 1 put: #[1 2].
	self deny: index isEmpty
]

{ #category : #tests }
SoilBTreeTest >> testIsOpen [
 	self assert: index isOpen.
 	index close.
 	self deny: index isOpen
]

{ #category : #tests }
SoilBTreeTest >> testLast [
	
	| capacity |
	capacity := index headerPage itemCapacity * 2.

	1 to: capacity - 1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 4.
	self assert: index last equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilBTreeTest >> testLastPage [
	
	| capacity lastItem |
	index maxLevel: 8.
	capacity := index firstPage itemCapacity * 100.

	1 to: capacity - 1 do: [ :n |
		index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	index at: capacity put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: 200.
	self assert: index lastPage index equals: 200.
	self assert: index lastPage isLastPage.
	lastItem := index lastPage itemAt: capacity ifAbsent: [nil].
	self assert: lastItem value equals: #[ 8 7 6 5 4 3 2 1 ].
]

{ #category : #tests }
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

{ #category : #tests }
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

{ #category : #tests }
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
		initializeFilesystem.
	
	self assert: page items first key equals:(index indexKey: #foo).
	"load succeeds"
	self assert: (index at: #foo) equals: #[ 1 2 3 4 5 6 7 8 ].

]

{ #category : #tests }
SoilBTreeTest >> testRemoveFromIndex [
	| entries |
	"We test that removing an entry will update the index"
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 1016;
		valueSize: 8.
	
	entries :=  #(104 247 56 281 61 286 66 337 308 1 400 272 347 335 45 62 207 7 123 140).
	
	
	entries do: [:toAdd |
		index at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].

	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
	"page 10 is the index page that has the index"
	self assert: (index pageAt: 10) items last key equals: 335.
	"now we remove 335"
	index removeKey: 335.
	"it is removed"
	self assert: (index at: 335 ifAbsent: [true]).
	"and the index is removed, too"
	self deny: (index pageAt: 10) items last key equals: 335.
	"we can add it back"
	index at: 335  put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index pageAt: 10) items last key equals: 335.
]

{ #category : #tests }
SoilBTreeTest >> testRemoveFromIndexAll [
	| entries remainingEntries |
	"We test that removing an entry will update the index"
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 512;
		valueSize: 512.
	
	entries :=  #(104 247 56 281 61 286 66 337 308 1 400 272 347 335 45 62 207 7 123 140).
	remainingEntries := entries asOrderedCollection.
	
	entries do: [:toAdd |
		index at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
	
	
	entries do: [:entry| |removed|
		removed := index removeKey: entry.
		self assert: removed key equals: entry.
		self assert: removed value equals: #[ 1 2 3 4 5 6 7 8 ].
		remainingEntries remove: entry.
		"check that all remaining entries can be found"	
		remainingEntries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]].
		"check size, this makes sure we can iterate over all remaining entries"
		self assert: index values size equals: remainingEntries size.	
		 ].
	self assert: index isEmpty.
	"and add back"
	entries do: [:toAdd |
		index at: toAdd  put: #[ 1 2 3 4 5 6 7 8 ] ].
	entries do: [:each | self assert: (index at: each ) equals: #[ 1 2 3 4 5 6 7 8 ]]
]

{ #category : #tests }
SoilBTreeTest >> testRemoveKey [

	| capacity removed |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	
	removed := index removeKey: 20.
	self assert: removed value equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: removed key equals: 20.
	
	self assert: (index at: 1) equals: #[ 1 2 3 4 5 6 7 8 ].
	self assert: (index at: capacity) equals: #[ 1 2 3 4 5 6 7 8 ].
	self should: [ index at: 20 ] raise: KeyNotFound.
	self should: [ index removeKey: 20  ] raise: KeyNotFound.
]

{ #category : #tests }
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

{ #category : #tests }
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
	
	"check size, this makes sure we can iterate over all remaining entries"
	self assert: index values size equals: entries size.	

]

{ #category : #tests }
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
		initializeFilesystem.
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (index at: each ) equals: (#[ 1 2 3 4 5 6 7 8 ] asByteArrayOfSize: 512)].
	
	"check size, this makes sure we can iterate over all remaining entries"
	self assert: index values size equals: entries size.	

]
