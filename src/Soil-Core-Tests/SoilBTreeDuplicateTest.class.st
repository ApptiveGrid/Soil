Class {
	#name : #SoilBTreeDuplicateTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'index'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #running }
SoilBTreeDuplicateTest >> setUp [ 
	super setUp.
	index := SoilBTree new 
		path: 'sunit-btree';
		destroy;
		initializeFilesystem;
		initializeHeaderPage;
		keySize: 8;
		valueSize: 8;
		uniqueKeys: false
]

{ #category : #running }
SoilBTreeDuplicateTest >> tearDown [ 
	index ifNotNil: [ 
		index close ].
	super tearDown
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAdd2 [

	| entries |
	index := SoilBTree new
		         path: 'sunit-btree';
		         destroy;
		         initializeFilesystem;
		         initializeHeaderPage;
		         keySize: 1016;
		         valueSize: 8;
					uniqueKeys: false.

	entries := #( 6 16 26 36 46 ).

	index at: 6 add: (6 asByteArrayOfSize: 8).
	self assertCollection: (index at: 6) hasSameElements: {6 asByteArrayOfSize: 8}.

	index at: 16 add: (16 asByteArrayOfSize: 8).
	self assertCollection: (index at: 6) hasSameElements: {6 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 16) hasSameElements: {16 asByteArrayOfSize: 8}.

	"We have two pages"
	self assert: index pages size equals: 2.
	"one index, one data"
	self assert: index indexPages size equals: 1.
	self assert: index dataPages size equals: 1.
	"index page has just the default entry for the smalles possible key"
	self assert: (index rootPage items collect: #key) size equals: 1.
	self assert: (index rootPage items collect: #key) first equals: 0.


	"with adding 26, we have to split the data page"
	index at: 26 add: (26 asByteArrayOfSize: 8).
	self assert: index pages size equals: 3.
	self assert: index indexPages size equals: 1.
	self assert: index dataPages size equals: 2.

	self assertCollection: (index at: 6) hasSameElements: {6 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 16) hasSameElements: {16 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 26) hasSameElements: {26 asByteArrayOfSize: 8}.

	"index page has two entries: 0 and 16"
	self assert: (index rootPage items collect: #key) size equals: 2.
	self assert: (index rootPage items collect: #key) first equals: 0.
	self assert: (index rootPage items collect: #key) second equals: 16.

	"adding 36 causes overlow in data node, have to add the new page to index"
	index at: 36 add: (36 asByteArrayOfSize: 8).

	self assert: index pages size equals: 4.
	self assert: index indexPages size equals: 1.
	self assert: index dataPages size equals: 3.

	self assertCollection: (index at: 6) hasSameElements: {6 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 16) hasSameElements: {16 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 26) hasSameElements: {26 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 36) hasSameElements: {36 asByteArrayOfSize: 8}.

	"index page has trhee entries: 0 and 16 and 26"
	self assert: (index rootPage items collect: #key) size equals: 3.
	self assert: (index rootPage items collect: #key) first equals: 0.
	self assert: (index rootPage items collect: #key) second equals: 16.
	self assert: (index rootPage items collect: #key) third equals: 26.

	"adding 46 causes overlow in data node and the index node"
	index at: 46 add: (46 asByteArrayOfSize: 8).

	self assert: index pages size equals: 7.
	self assert: index indexPages size equals: 3.
	self assert: index dataPages size equals: 4.
	
	self assertCollection: (index at: 6) hasSameElements: {6 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 16) hasSameElements: {16 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 26) hasSameElements: {26 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 36) hasSameElements: {36 asByteArrayOfSize: 8}.
	self assertCollection: (index at: 46) hasSameElements: {46 asByteArrayOfSize: 8}.

	"index page has three entries: 0 and 16 and 26"

	self assert: (index rootPage items collect: #key) first equals: 0.
	self assert: (index rootPage items collect: #key) second equals: 26.

	self assert: index indexPages second items second key equals: 16.
	self assert: index indexPages first items second key equals: 36
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAddFirstOverflow [

	| page capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 126.
	"if we add a page, the current one is split and half is moved there"
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 3.
	page := index pageAt: 3.
	self assert: page numberOfItems equals: 128.
	self assert: page items first key equals: 127.
	self assert: page items last key asByteArray equals: #[ 254 ].
	"check that the next pointer is correct after split"
	self
		assert: (index pageAt: index headerPage next)
		identicalTo: (index pageAt: 3)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAddRandom [

	| numEntries entries |
	"just some random adding and checking that we can find it. tree is configured to create lots of pages"
	index := SoilBTree new
		         path: 'sunit-btree-testAddRandom';
		         destroy;
		         initializeFilesystem;
		         initializeHeaderPage;
		         keySize: 512;
		         valueSize: 512.

	numEntries := 20.
	entries := Set new: numEntries.


	numEntries timesRepeat: [
		| toAdd |
		toAdd := (numEntries * 20) atRandom.
		entries add: toAdd.
		index at: toAdd add: (toAdd asByteArrayOfSize: 8) ].

	"check size"
	self assert: index size equals: entries size.

	"can we find all the keys we added?"
	entries do: [ :each |
		self assert: (index at: each) equals: (each asByteArrayOfSize: 8) ].

	"iterate index, all should be in entries"
	index do: [ :each |
		self assert: each equals: (each asByteArrayOfSize: 8) ].
	index reverseDo: [ :each |
		self assert: each equals: (each asByteArrayOfSize: 8) ]
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAddSecondOverflow [

	| page capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 126.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n |
		index at: capacity + n add: (capacity + n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
	page := index pageAt: 4.
	self assert: page numberOfItems equals: 253.
	self assert: page items first key equals: 254.
	"check that the next pointer is correct after split"
	self
		assert: ((index headerPage nextPageIn: index) nextPageIn: index)
		identicalTo: (index pageAt: 4).
	index writePages
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAddSecondOverflowReload [

	| page capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 126.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n |
		index at: capacity + n add: (capacity + n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
	page := index pageAt: 4.
	self assert: page numberOfItems equals: 253.
	self assert: page items first key equals: 254.
	"check that the next pointer is correct after split"
	self
		assert: ((index headerPage nextPageIn: index) nextPageIn: index)
		identicalTo: (index pageAt: 4).

	index writePages.
	index close.
	index := SoilBTree new
		         path: 'sunit-btree';
		         initializeFilesystem.
	self
		assertCollection: (index at: capacity)
		hasSameElements: {capacity asByteArrayOfSize: 8}
]

{ #category : #'as yet unclassified' }
SoilBTreeDuplicateTest >> testAddingDuplicateKeyAcrossPages [

	| elements iterator ids |
	index allowDuplicateKeys.
	iterator := index newIterator.
	1 to: 250 do: [ :n | iterator at: n add: n asDummySoilObjectId ].
	ids := OrderedCollection new.
	1 to: 6 do: [ :n |
		ids add: n asDummySoilObjectId.
		iterator at: 251 add: n asDummySoilObjectId ].
	self assert: index size equals: 256.
	elements := iterator valuesAt: 251.
	self assertCollection: elements hasSameElements: ids
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAt [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 3.
	self assert: (index pageAt: 1) numberOfItems equals: 126.
	"if we add a page, the current one is split and half is moved there"
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 3.

	self assertCollection: (index at: 1) hasSameElements: {1 asByteArrayOfSize: 8}.
	self assertCollection: (index at: capacity) hasSameElements: {capacity asByteArrayOfSize: 8}.
	self assertCollection: (index at: capacity + 1) hasSameElements: {(capacity + 1) asByteArrayOfSize: 8}.
	
	self should: [ index at: capacity + 2 ] raise: KeyNotFound
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testAtSecondOverflow [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity * 2 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
	self assert: (index pageAt: 1) numberOfItems equals: 126.
	"if we add a page, the current one is split and half is moved there"
	1 to: capacity do: [ :n |
		index at: capacity + n add: (capacity + n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 6.

	self assertCollection: (index at: 1) hasSameElements: {1 asByteArrayOfSize: 8}.
	self assertCollection: (index at: capacity) hasSameElements: {capacity asByteArrayOfSize: 8}.
	self assertCollection: (index at: capacity + 1) hasSameElements: {(capacity + 1) asByteArrayOfSize: 8}.
	self assertCollection: (index at: capacity + capacity) hasSameElements: {(capacity + capacity) asByteArrayOfSize: 8}.
			
	self should: [ index at: capacity * 2 + 1 ] raise: KeyNotFound
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testCreation [
	"we alwaus create one data page and the root index"
	self assert: index pages size equals: 2.
	"both pages start as dirty"
	self assert: (index pages at: 1) needsWrite.
	self assert: (index pages at: 2) needsWrite
]

{ #category : #'as yet unclassified' }
SoilBTreeDuplicateTest >> testDuplicateKeysRoundtripAndCompact [

	index allowDuplicateKeys.
	self assert: index headerPage uniqueKeys equals: false.

	index writePages.
	index
		reopen;
		compact.
	self assert: index headerPage uniqueKeys equals: false.
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testFirst [

	| capacity |
	capacity := index headerPage itemCapacity * 2.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
	self assert: index first equals: (1 asByteArrayOfSize: 8).
	self assert: (index first: 2) second equals: (2 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testFreePageAdd [

	| iterator |
	iterator := index newIterator.
	1 to: 2500 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 20.
	self assert: index headerPage firstFreePageIndex equals: 0.
	500 to: 1500 do: [ :n | iterator removeKey: n value: (n asByteArrayOfSize: 8)].
	self assert: index headerPage lastPageOffset equals: 20.
	self assert: index headerPage firstFreePageIndex equals: 0.
	index cleanUpToVersion: nil.
	self assert: index headerPage lastPageOffset equals: 20.
	"the first page that gets empty is reused as free list page"
	self assert: index headerPage firstFreePageIndex equals: 6.
	"subsequent removed pages are added to the first page"
	self
		assertCollection: (index store pageAt: 6) pageIndexes
		hasSameElements: #( 7 8 9 10 11 12 )
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testFreePageAddNested [

	| iterator nestedFreeIndexes |
	index
		maxLevel: 8;
		valueSize: 512.
	iterator := index newIterator.
	"create enough pages to test"
	1 to: 9000 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 3017.
	self assert: index headerPage firstFreePageIndex equals: 0.
	"now we free more pages than a free page list has capacity"
	10 to: 8990 do: [ :n | iterator removeKey: n value: (n asByteArrayOfSize: 8)].
	index cleanUpToVersion: nil.
	self assert: index headerPage firstFreePageIndex equals: 5.
	self assert: (index store pageAt: 5) pageIndexes size equals: 1018.
	"as there were more than free list capacity there is a next free
	list page"
	self assert: (index store pageAt: 5) next equals: 1025.
	nestedFreeIndexes := (index store pageAt: 1025) pageIndexes copy
		                     copyWith: 1025.
	"we fill the index with enough elements to use all free pages including the nested 
	ones"
	1 to: 15 * 1018 do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].
	"there should be no more free page"
	self assert: index headerPage firstFreePageIndex equals: 0.
	"and all pageIndexes of the next free page should be included"
	self assert:
		((index store pages collect: #offset) includesAll: nestedFreeIndexes)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testFreePageReuse [

	| iterator |
	iterator := index newIterator.
	1 to: 2500 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 20.
	self assert: index headerPage firstFreePageIndex equals: 0.
	500 to: 1500 do: [ :n | iterator removeKey: n  value: (n asByteArrayOfSize: 8)].
	index cleanUpToVersion: nil.
	self assert: index headerPage lastPageOffset equals: 20.
	2501 to: 2750 + 250 do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].
	index cleanUpToVersion: nil.
	"first free page is #6 with content #( 9 10 11 12 ). Adding 500 entries should remove 
	two pages for reuse"
	self
		assertCollection: (index store pageAt: 6) pageIndexes
		hasSameElements: #( 11 12 )
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testFreePageReuseAtEndAppend [

	| iterator |
	iterator := index newIterator.
	1 to: 2500 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 20.
	self assert: index headerPage firstFreePageIndex equals: 0.
	500 to: 1500 do: [ :n | iterator removeKey: n value: (n asByteArrayOfSize: 8)].
	index cleanUpToVersion: nil.
	self assert: index headerPage lastPageOffset equals: 20.
	self
		assertCollection: (index store pageAt: 6) pageIndexes
		hasSameElements: #( 7 8 9 10 11 12 ).
	iterator := index newIterator.
	2501 to: 3500 do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].
	index cleanUpToVersion: nil.
	"readding the same amount of entries but at the end should reuse all 
	free pages making first free 0."
	self assert: index headerPage firstFreePageIndex equals: 0.
	"as the new entries did not fit exactly we have one more page at the 
	end which should have update the header page"
	self assert: index headerPage lastPageOffset equals: 21
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testIndexRewriting [

	| capacity fileSizeBefore |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	index flush.
	self assert: index headerPage lastPageOffset equals: 3.
	self assert: (index pageAt: 3) items size equals: 128.
	self assert: (index pageAt: 1) items size equals: 126.
	fileSizeBefore := index path size.
	index newPluggableRewriter rewrite.
	self assert: index headerPage lastPageOffset equals: 3.
	self assert: (index pageAt: 3) items size equals: 128.
	self assert: (index pageAt: 1) items size equals: 126.

	self assert: index path size equals: fileSizeBefore
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testIndexRewritingWithCleaning [

	| capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	index flush.
	1 to: capacity do: [ :n | index at: n add: SoilObjectId removed ].

	index newPluggableRewriter cleanRemoved run.
	self assert: index headerPage lastPageOffset equals: 3.
	self assert: (index pageAt: 1) items size equals: 126.
	self
		assert: (index at: capacity + 1) first asByteArray
		equals: (capacity + 1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testIsEmpty [

	self assert: index isEmpty.
	index at: 1 add: #[ 1 2 ].
	self deny: index isEmpty
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testIsOpen [
 	self assert: index isOpen.
 	index close.
 	self deny: index isOpen
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testLast [

	| capacity |
	capacity := index headerPage itemCapacity * 2.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 4.
	self assert: index last equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testLastPage [

	| capacity lastItem |
	index maxLevel: 8.
	capacity := index firstPage itemCapacity * 100.

	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 200.
	self assert: index lastPage offset equals: 200.
	self assert: index lastPage isLastPage.
	lastItem := index lastPage itemAt: capacity ifAbsent: [ nil ].
	self assert: lastItem value equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testOverflowCopyOnWriteSplitting [

	| page capacity copyOnWrite |
	copyOnWrite := index asCopyOnWrite.
	capacity := copyOnWrite headerPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n |
	"make sure to use the same key"
	copyOnWrite at: 1 add: (n asByteArrayOfSize: 8) ].
	self assert: copyOnWrite pages size equals: 2.

	page := copyOnWrite pageAt: 3.
	self assert: page numberOfItems equals: 127.
	self assert: page items first key equals: 1.
	self assert: page items last key  equals: 1.
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testPageAddFirst [

	| page indexPage |
	index at: 1 add: (1 asByteArrayOfSize: 8).
	index writePages.
	self assert: index pages size equals: 2.
	page := index headerPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (index indexKey: 1).
	"the index page was updated"
	indexPage := index rootPage.
	"Index has been updated"
	self assert: indexPage items size equals: 1
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testPageAddFirstAndLoad [

	| page indexPage |
	index at: 1 add: (1 asByteArrayOfSize: 8).
	index writePages.
	self assert: index pages size equals: 2.
	page := index headerPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (index indexKey: 1).
	"the index page was updated"
	indexPage := index rootPage.
	"Index has been updated"
	self assert: indexPage items size equals: 1.

	"load back"

	index close.
	index := SoilBTree new
		         path: 'sunit-btree';
		         initializeFilesystem.

	self assert: page items first key equals: (index indexKey: 1).
	"load succeeds"
	self assertCollection: (index at: 1) hasSameElements: {1 asByteArrayOfSize: 8}
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testRecyclePage [

	| capacityFirst offset capacity iterator counter |
	capacityFirst := index firstPage itemCapacity.
	1 to: capacityFirst do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 3.
	offset := capacityFirst.
	iterator := index newIterator.
	2 to: 6 do: [ :p |
		index at: offset + 1 add: (offset + 1 asByteArrayOfSize: 8).
		capacity := index lastPage itemCapacity.
		offset + 2 to: offset + capacity do: [ :n |
		index at: n add: (n asByteArrayOfSize: 8) ].
		offset := offset + capacity ].
	self assert: index pages size equals: 13.
	index recyclePage: (index pages at: 3).
	self assert: index pages size equals: 13.
	"page 3 is the recycled page"
	self assert: index firstFreePage offset equals: 3.
	"the page is a free page"
	self assert: index firstFreePage class equals: SoilFreePage.
	"after, index 3 should not be a value in any index page item"
	index indexPages do: [ :indexPage |
		self assert:
			(indexPage items noneSatisfy: [ :item | item value == 3 ]) ].
	"if we follow the next pointer, we find only the non-recyled data pages"
	iterator := index newIterator.
	counter := 0.
	iterator pagesDo: [ :page | counter := counter + 1 ].
	"13 - 1 indexPage - 1 recycled page"
	self assert: counter equals: 11
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testRemoveFromIndex [

	| entries |
	"We test that removing an entry will update the index"
	index := SoilBTree new
		         path: 'sunit-btree';
		         destroy;
		         initializeFilesystem;
		         initializeHeaderPage;
		         keySize: 1016;
		         valueSize: 8.

	entries := #( 104 247 56 281 61 286 66 337 308 1 400 272 347 335 45
	              62 207 7 123 140 ).


	entries do: [ :toAdd |
		index at: toAdd add: (toAdd asByteArrayOfSize: 8) ].

	"can we find all the keys we added?"
	entries do: [ :each |
		self assert: (index at: each) equals: (each asByteArrayOfSize: 8) ].
	"page 10 is the index page that has the index"
	self assert: (index pageAt: 10) items last key equals: 335.
	"now we remove 335"
	index removeKey: 335.
	"it is removed"
	self assert: (index at: 335 ifAbsent: [ true ]).
	"and the index is removed, too"
	self deny: (index pageAt: 10) items last key equals: 335.
	"we can add it back"
	index at: 335 add: (335 asByteArrayOfSize: 8).
	self assert: (index pageAt: 10) items last key equals: 335.
	self
		assert: (index pageAt: 10) items last value
		equals: (335 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testRemoveFromIndexAll [

	| entries remainingEntries |
	"We test that removing an entry will update the index"
	index := SoilBTree new
		         path: 'sunit-btree';
		         destroy;
		         initializeFilesystem;
		         initializeHeaderPage;
					uniqueKeys: false;
		         keySize: 512;
		         valueSize: 512.

	entries := #( 104 247 56 281 61 286 66 337 308 1 400 272 347 335 45
	              62 207 7 123 140 ).
	remainingEntries := entries asOrderedCollection.

	entries do: [ :toAdd |
		index at: toAdd add: (toAdd asByteArrayOfSize: 8) ].
	"can we find all the keys we added?"
	entries do: [ :each |
		self assertCollection: (index at: each)  hasSameElements: {each asByteArrayOfSize: 8} ].

	
	entries do: [ :entry |
		| removed |
		removed := index removeKey: entry.
		self assert: removed equals: (removed asByteArrayOfSize: 8).
		remainingEntries remove: entry.
		"check that all remaining entries can be found"
		remainingEntries do: [ :each |
			self assert: index values size equals: remainingEntries size ].
		"check size, this makes sure we can iterate over all remaining entries"
		 ].
	self assert: index isEmpty.

	"add data pages are empty"
	index dataPages do: [ :dataPage | self assert: dataPage isEmpty ].

	"and add back"
	entries do: [ :toAdd |
		index at: toAdd add: (toAdd asByteArrayOfSize: 8) ].
	entries do: [ :each |
		self assertCollection: (index at: each) hasSameElements: {each asByteArrayOfSize: 8} ]
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testRemoveKey [

	| capacity removed |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].

	removed := index removeKey: 20.
	self assert: removed equals: (20 asByteArrayOfSize: 8).

	self assertCollection: (index at: 1) hasSameElements: {(1 asByteArrayOfSize: 8)}.
	self assertCollection: (index at: capacity) hasSameElements: {(capacity asByteArrayOfSize: 8)}.
	self should: [ index at: 20 ] raise: KeyNotFound.
	self should: [ index removeKey: 20 ] raise: KeyNotFound
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testSize [

	| capacity |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 3.
	self assert: index size equals: capacity + 1
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testSplitIndexPage [

	| entries |
	"this test leads to a split of a non-root index page"
	index := SoilBTree new
		         path: 'sunit-btree';
		         destroy;
		         initializeFilesystem;
		         initializeHeaderPage;
					uniqueKeys: false;
		         keySize: 512;
		         valueSize: 512.

	entries := #( 104 247 56 281 61 286 66 337 308 1 400 272 347 335 45
	              62 207 7 123 140 ).


	entries do: [ :toAdd |
		index at: toAdd add: (toAdd asByteArrayOfSize: 8) ].

	"can we find all the keys we added?"
	entries do: [ :each |
		self assertCollection: (index at: each) hasSameElements: {each asByteArrayOfSize: 8} ].

	"check size, this makes sure we can iterate over all remaining entries"
	self assert: index values size equals: entries size
]

{ #category : #tests }
SoilBTreeDuplicateTest >> testSplitIndexPageReleoad [

	| entries |
	"this test leads to a split of a non-root index page"
	index := SoilBTree new
		         path: 'sunit-btree';
		         destroy;
		         initializeFilesystem;
		         initializeHeaderPage;
					uniqueKeys: false;
		         keySize: 512;
		         valueSize: 512.

	entries := #( 104 247 56 281 61 286 66 337 308 1 400 272 347 335 45
	              62 207 7 123 140 ).


	entries do: [ :toAdd |
		index at: toAdd add: (toAdd asByteArrayOfSize: 512) ].

	"can we find all the keys we added?"
	entries do: [ :each |
			self assertCollection: (index at: each) hasSameElements: {each asByteArrayOfSize: 512}].

	"write and reload"
	index writePages.
	index close.
	index := SoilBTree new
		         path: 'sunit-btree';
		         initializeFilesystem.

	"can we find all the keys we added?"
	entries do: [ :each |
		self assertCollection: (index at: each) hasSameElements: {each asByteArrayOfSize: 512} ].

	"check size, this makes sure we can iterate over all remaining entries"
	self assert: index values size equals: entries size
]
