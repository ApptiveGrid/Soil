Class {
	#name : #SoilSkipListTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'index',
		'uniqueKeys'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #'building suites' }
SoilSkipListTest class >> testParameters [
	^ ParametrizedTestMatrix new
		addCase: { #uniqueKeys -> true };
		addCase: { #uniqueKeys -> false };
		yourself
]

{ #category : #running }
SoilSkipListTest >> assertSoilDuplicate: actual equals: expected [
	uniqueKeys
		ifTrue: [self assert: actual equals: expected  ]
		ifFalse: [ self assertCollection: actual hasSameElements: {expected} ] 
]

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
		valueSize: 8;
		uniqueKeys: uniqueKeys
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
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: 252.
	self assert: page items last key asByteArray equals: #[ 252 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflowReload [

	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: 252.
	self assert: page items last key asByteArray equals: #[ 252 ].

	"write it and then read it back with a new SoilSkipList"
	index writePages.
	index close.
	index := SoilSkipList new
		         path: 'sunit-skiplist';
		         initializeFilesystem.
	"we should be able to do a lookup"
	self
		assertSoilDuplicate: ((index at: capacity))
		equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflowSplitting [

	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index at: capacity - 3 add: (capacity - 3 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 125.
	self assert: page items first key equals: 253.
	self assert: page items last key asByteArray equals: #[ 1 245 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetween [

	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index
		at: (capacity / 2) floor
		add: ((capacity / 2) floor asByteArrayOfSize: 8).
	self assert: index pages size equals: 1.
	page := index pageAt: 1.
	self assert: page numberOfItems equals: 251.
	self assert: (page items at: (capacity / 2) floor) key equals: 125
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverflowing [

	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index at: 32 add: (32 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	page := index pageAt: 2.
	self assert: page numberOfItems equals: 125.
	self assert: page items first key equals: 253.
	self assert: page items last key asByteArray equals: #[ 1 245 ].
	index writePages
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverwriting [

	| page capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index at: 31 add: #[ 8 7 6 5 4 3 2 1 ].
	self assert: index pages size equals: (uniqueKeys ifTrue: [1] ifFalse: [2]).
	page := index pageAt: 1.
	self assert: page numberOfItems equals: (uniqueKeys ifTrue: [251] ifFalse: [127]).
	self assert: (page items at: (uniqueKeys ifTrue: [16] ifFalse: [17])) value equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddLastFitting [

	| page |
	1 to: 61 do: [ :n |
		index at: (index indexKey: n asString) add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index
		at: (index indexKey: 63 asString)
		add: (63 asByteArrayOfSize: 8).
	self assert: index pages size equals: 1.
	page := index pageAt: 1.
	self assert: page numberOfItems equals: 62.
	self assert: page items last key asByteArray equals: #[ 54 51 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddRandom [

	| numEntries entries result |
	"just some random adding and checking that we can find it, configured to create lots of pages"
	index 
		maxLevel: 10;
		keySize: 512;
		valueSize: 512.

	numEntries := 20.
	entries := Set new: numEntries.


	numEntries timesRepeat: [
		| toAdd |
		toAdd := (numEntries * 20) atRandom.
		entries add: toAdd.
		index at: toAdd add: toAdd asDummySoilObjectId ].

	"check size"
	self assert: index size equals: entries size.

	"can we find all the keys we added?"
	entries do: [ :each |
		self assertSoilDuplicate: (index at: each) equals: each asDummySoilObjectId ].

	"iterate index, all should be in entries"
	result := OrderedCollection new.
	"we use do: to iterate over the index"
	index do: [ :each |
		result add: each].
	
	entries := (entries collect: #asDummySoilObjectId).
	result do: [ :each | self assert: (entries includes: each) ].
	
	index reverseDo: [ :each |
		result add: each].
	result do: [ :each | self assert: (entries includes: each) ].
]

{ #category : #tests }
SoilSkipListTest >> testAddingDuplicateKeyAcrossPages [

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
SoilSkipListTest >> testAt [

	| capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.

	"we should be able to find the key that is on the second page"
	self
		assertSoilDuplicate: (index at: capacity + 1)
		equals: (capacity + 1 asByteArrayOfSize: 8).
	self should: [ index at: capacity + 2 ] raise: KeyNotFound
]

{ #category : #tests }
SoilSkipListTest >> testAtIndex [

	| value |
	1 to: 200 do: [ :n | index at: n add: n asSoilObjectId ].
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
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	col := OrderedCollection new.
	index do: [ :item | col add: item ].
	self assert: col first equals: (1 asByteArrayOfSize: 8).
	self assert: col size equals: capacity + 1
]

{ #category : #tests }
SoilSkipListTest >> testFindKey [

	| value |
	1 to: 200 do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	value := index find: 133.
	self assertSoilDuplicate: value equals: (133 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testFindKeyReverse [

	| value |
	200 to: 1 by: -1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	"skipList writePages."
	value := index find: 133.
	self assertSoilDuplicate: value equals: (133 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testFirst [

	| capacity |
	capacity := index firstPage itemCapacity * 2.

	2 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index at: 1 add: (1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 3.
	self assert: index first equals: (1 asByteArrayOfSize: 8).
	self assert: (index first: 2) second equals: (2 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testFirstArgLargerThenSize [

	1 to: 4 do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	self assert: (index first: 5) size equals: 4
]

{ #category : #tests }
SoilSkipListTest >> testFreePageAdd [

	| iterator |
	iterator := index newIterator.
	1 to: 2500 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 10.
	self assert: index headerPage firstFreePageIndex equals: 0.
	500 to: 1500 do: [ :n | 
		uniqueKeys 
			ifTrue: [ iterator removeKey: n  ] 
			ifFalse: [ iterator removeKey: n value: (n asByteArrayOfSize: 8) ] 
		].
	self assert: index headerPage lastPageOffset equals: 10.
	self assert: index headerPage firstFreePageIndex equals: 0.
	index cleanUpToVersion: nil.
	self assert: index headerPage lastPageOffset equals: 10.
	"the first page that gets empty is reused as free list page"
	self assert: index headerPage firstFreePageIndex equals: 3.
	"subsequent removed pages are added to the first page"
	self
		assertCollection: (index store pageAt: 3) pageIndexes
		hasSameElements: #( 4 5 )
]

{ #category : #tests }
SoilSkipListTest >> testFreePageAddAndDelete [

	| iterator |
	uniqueKeys ifFalse: [ ^self ]. "test foruniqueKeys only"
	iterator := index newIterator.
	1 to: 280 do: [ :n | iterator at: n add: n asDummySoilObjectId ].
	self assert: index headerPage lastPageOffset equals: 2.
	self assert: index headerPage firstFreePageIndex equals: 0.
	1 to: 1989 do: [ :n |
		iterator at: 280 + n add: (200 + n) asDummySoilObjectId.
		iterator removeKey: n.
		index cleanUpToVersion: nil ].

	self assert: index headerPage lastPageOffset equals: 4.
	self assert: (index store pageAt: 4) pageIndexes isEmpty.
	self assert: (index store pageAt: 4) isFreePage.
]

{ #category : #tests }
SoilSkipListTest >> testFreePageAddNested [

	| iterator nestedFreeIndexes |
	index
		maxLevel: 8;
		valueSize: 512.
	iterator := index newIterator.
	"create enough pages to test"
	1 to: 9000 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 1286.
	self assert: index headerPage firstFreePageIndex equals: 0.
	"now we free more pages than a free page list has capacity"
	10 to: 8990 do: [ :n | 
			uniqueKeys 
			ifTrue: [ iterator removeKey: n  ] 
			ifFalse: [ iterator removeKey: n value:  (n asByteArrayOfSize: 8)]].
	index cleanUpToVersion: nil.
	self assert: index headerPage firstFreePageIndex equals: 3.
	self assert: (index store pageAt: 3) pageIndexes size equals: 1019.
	"as there were more than free list capacity there is a next free
	list page"
	self assert: (index store pageAt: 3) next equals: 1023.
	nestedFreeIndexes := (index store pageAt: 1023) pageIndexes copy
		                     copyWith: 1023.
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
SoilSkipListTest >> testFreePageReuse [

	| iterator |
	iterator := index newIterator.
	1 to: 2500 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 10.
	self assert: index headerPage firstFreePageIndex equals: 0.
	500 to: 1500 do: [ :n | 
			uniqueKeys 
			ifTrue: [ iterator removeKey: n  ] 
			ifFalse: [ iterator removeKey: n value:  (n asByteArrayOfSize: 8)]].
	index cleanUpToVersion: nil.
	self assert: index headerPage lastPageOffset equals: 10.
	2501 to: 2750 do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].
	index cleanUpToVersion: nil.
	"first free page is #3 with content #( 4 5 ). Adding 250 entries should remove 
	one page #4 for reuse"
	self
		assertCollection: (index store pageAt: 3) pageIndexes
		hasSameElements: #( 5 )
]

{ #category : #tests }
SoilSkipListTest >> testFreePageReuseAtEndAppend [

	| iterator |
	iterator := index newIterator.
	1 to: 2500 do: [ :n | iterator at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index headerPage lastPageOffset equals: 10.
	self assert: index headerPage firstFreePageIndex equals: 0.
	500 to: 1500 do: [ :n | 
			uniqueKeys 
			ifTrue: [ iterator removeKey: n  ] 
			ifFalse: [ iterator removeKey: n value:  (n asByteArrayOfSize: 8)] ].
	index cleanUpToVersion: nil.
	self assert: index headerPage lastPageOffset equals: 10.
	self
		assertCollection: (index store pageAt: 3) pageIndexes
		hasSameElements: #( 4 5 ).
	iterator := index newIterator.
	2501 to: 3500 do: [ :n |
	iterator at: n add: (n asByteArrayOfSize: 8) ].
	index cleanUpToVersion: nil.
	"readding the same amount of entries but at the end should reuse all 
	free pages making first free 0."
	self assert: index headerPage firstFreePageIndex equals: 0.
	"as the new entries did not fit exactly we have one more page at the 
	end which should have update the header page"
	self assert: index headerPage lastPageOffset equals: 11.
	"page #3 was the first free page so it was recycled last. Therefor the 
	page #3 should point to page #11 which should be the last"
	self assert: (index store pageAt: 3) right first equals: 11.
	self assert: (index store pageAt: 11) right first equals: 0
]

{ #category : #tests }
SoilSkipListTest >> testIndexRewriting [

	| capacity fileSizeBefore |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	index flush.
	fileSizeBefore := index path size.
	index newPluggableRewriter rewrite.
	self assert: index headerPage lastPageOffset equals: 2.
	self assert: (index pageAt: 2) items size equals: 1
	"self assert: index path size equals: fileSizeBefore"
]

{ #category : #tests }
SoilSkipListTest >> testIndexRewritingWithCleaning [

	| capacity |
	index uniqueKeys ifFalse: [ ^ self ]. 
	"we are testing cleanup for iterator level remove
	This test makes only sense for uniqueKeys as only here we can override a value with a removed ID using at:add:"
	capacity := index firstPage itemCapacity.
	1 to: capacity + 1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	index flush.
	1 to: capacity do: [ :n | index at: n add: (SoilRemovedObjectId for:  (n asByteArrayOfSize: 8)) ].

	index newPluggableRewriter cleanRemoved rewrite.
	self assert: index headerPage lastPageOffset equals: 1.
	self assert: (index pageAt: 1) items size equals: 1.
	self
		assertSoilDuplicate: (index at: capacity + 1)
		equals: (capacity + 1 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testIsEmpty [

	self assert: index isEmpty.
	index at: 1 add: #[ 1 2 ].
	self deny: index isEmpty
]

{ #category : #tests }
SoilSkipListTest >> testIsOpen [
	self assert: index isOpen.
	index close.
	self deny: index isOpen
]

{ #category : #tests }
SoilSkipListTest >> testLast [

	| capacity |
	capacity := index firstPage itemCapacity * 2.

	1 to: capacity - 1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	index at: capacity add: (capacity asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	self assert: index last equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testLastPage [

	| capacity lastItem |
	index maxLevel: 8.
	capacity := index firstPage itemCapacity * 100.

	1 to: capacity - 1 do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	index at: capacity add: (capacity asByteArrayOfSize: 8).
	self assert: index pages size equals: 99.
	self assert: index lastPage offset equals: 99.
	self assert: index lastPage isLastPage.
	lastItem := index lastPage itemAt: capacity ifAbsent: [ nil ].
	self assert: lastItem value equals: (capacity asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testLatestVersionRoundtrip [

	1 to: 10 do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index removeKey: 4.
	self assert: index pages size equals: 1.
	self assert: index size equals: 9.

	"write it and then read it back with a new SoilSkipList"
	index writePages.
	index close.
	index := SoilSkipList new
		         path: 'sunit-skiplist';
		         open.
	self assert: index size equals: 9
]

{ #category : #tests }
SoilSkipListTest >> testMorePages [

	1 to: 512 do: [ :n |
		index at: (index indexKey: n asString) add: (n asByteArrayOfSize: 8) ].
	index writePages.
	self assert: index pages size equals: 3
]

{ #category : #tests }
SoilSkipListTest >> testOverflowCopyOnWriteAppending [

	| page capacity copyOnWrite |
	copyOnWrite := index asCopyOnWrite.
	capacity := copyOnWrite firstPage itemCapacity.
	1 to: capacity do: [ :n |
	copyOnWrite at: n add: (n asByteArrayOfSize: 8) ].
	self assert: copyOnWrite pages size equals: 1.
	copyOnWrite at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: copyOnWrite pages size equals: 2.
	page := copyOnWrite pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: 252.
	self assert: page items last key asByteArray equals: #[ 252 ]
]

{ #category : #tests }
SoilSkipListTest >> testOverflowCopyOnWriteSplitting [

	| page capacity copyOnWrite |
	copyOnWrite := index asCopyOnWrite.
	capacity := copyOnWrite firstPage itemCapacity.
	1 to: capacity * 2 by: 2 do: [ :n |
	copyOnWrite at: n add: (n asByteArrayOfSize: 8) ].
	self assert: copyOnWrite pages size equals: 1.
	copyOnWrite at: 2 add: (2 asByteArrayOfSize: 8).
	self assert: copyOnWrite pages size equals: 2.
	page := copyOnWrite pageAt: 2.
	self assert: page numberOfItems equals: 125.
	self assert: page items first key equals: 253.
	self assert: page items last key asByteArray equals: #[ 1 245 ]
]

{ #category : #tests }
SoilSkipListTest >> testPageAddFirst [

	| page |
	index at: #foo add: #[ 1 2 3 4 5 6 7 8 ].
	index writePages.
	self assert: index pages size equals: 1.
	page := index firstPage.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: (index indexKey: #foo)
]

{ #category : #tests }
SoilSkipListTest >> testPageCodeNoDuplicates [ 
	| pageCodes |
	pageCodes := (SoilIndexPage allSubclasses collect: #pageCode) reject: [:each | each == 0 ].
	self assert: pageCodes size equals: pageCodes asSet size 
]

{ #category : #tests }
SoilSkipListTest >> testRecyclePage [

	| capacityFirst offset capacity iterator counter |
	capacityFirst := index firstPage itemCapacity.
	1 to: capacityFirst do: [ :n |
	index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size equals: 1.
	offset := capacityFirst.
	iterator := index newIterator.
	2 to: 6 do: [ :p |
		index at: offset + 1 add: (offset + 1 asByteArrayOfSize: 8).
		capacity := index lastPage itemCapacity.
		offset + 2 to: offset + capacity do: [ :n |
		index at: n add: (n asByteArrayOfSize: 8) ].
		offset := offset + capacity ].
	self assert: index pages size equals: 6.
	index recyclePage: (index pages at: 3).
	self assert: index pages size equals: 6.

	"page 3 is the recycled page"
	self assert: index firstFreePage offset equals: 3.
	"and it is a FreePage"
	self assert: index firstFreePage class equals: SoilFreePage.
	"if we follow the next pointer, we find only the non-recyled data pages"
	iterator := index newIterator.
	counter := 0.
	iterator pagesDo: [ :page | counter := counter + 1 ].
	"6 minus 1 recycled page"
	self assert: counter equals: 5
]

{ #category : #tests }
SoilSkipListTest >> testRemoveAllFromPage [

	| entries |
	uniqueKeys ifFalse: [ ^self skip]. "To check: error with duplicate keys"
	
	"We test that after removing all entries from one page, #nextAssociation will continue to the next page"
	index keySize: 1016. "huge keySize forces multiple pages"
	entries := #( 104 247 56 281 61 286 66 337 308 1 400 272 347 335 45
	              62 207 7 123 140 ).


	entries do: [ :toAdd |
		index at: toAdd add: (toAdd asByteArrayOfSize: 8) ].

	"can we find all the keys we added?"
	entries do: [ :each |
		self assertSoilDuplicate: (index at: each) equals: (each asByteArrayOfSize: 8) ].
	"#values iterates using #basicNextAssociation"
	self assert: index values size equals: entries size.

	index removeKey: 247.
	index removeKey: 272.
	self assert: (index pageAt: 3) isEmpty.
	"iterating goes beyond the empty page"
	self assert: index values size equals: entries size - 2.
	
	"We can search for a key that is in a page after the empty page"
	self assert: (index newIterator find: 281) notNil
]

{ #category : #tests }
SoilSkipListTest >> testRemoveKey [

	| capacity removed |
	capacity := index headerPage itemCapacity.
	1 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].

	removed := index removeKey: 20.
	self assertSoilDuplicate: removed equals: (20 asByteArrayOfSize: 8).

	self assertSoilDuplicate: (index at: 1) equals: (1 asByteArrayOfSize: 8).
	self assertSoilDuplicate: (index at: capacity) equals: (capacity asByteArrayOfSize: 8).
	self should: [ index at: 20 ] raise: KeyNotFound.
	index at: 20 add: (20 asByteArrayOfSize: 8).
	self assertSoilDuplicate: (index at: 20) equals: (20 asByteArrayOfSize: 8).

	self should: [ index removeKey: capacity + 1 ] raise: KeyNotFound
]

{ #category : #tests }
SoilSkipListTest >> testSize [

	| capacity |
	capacity := index firstPage itemCapacity.
	index at: 1 add: (1 asByteArrayOfSize: 8).
	2 to: capacity do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index at: capacity + 1 add: (capacity + 1 asByteArrayOfSize: 8).
	self assert: index pages size equals: 2.
	self assert: index size equals: capacity + 1
]

{ #category : #tests }
SoilSkipListTest >> testSplitLastPage [

	| headerCapacity itemCapacity |
	"fill the header page"
	headerCapacity := index headerPage itemCapacity.
	1 to: headerCapacity do: [ :n | index at: n add: n ].
	self assert: index pages size equals: 1.
	"trigger page split and check it happened"
	index at: headerCapacity + 1 add: 0.
	self assert: index pages size equals: 2.
	"fill second page til the end"
	itemCapacity := (index pageAt: 2) itemCapacity.
	headerCapacity + 2 to: headerCapacity + itemCapacity do: [ :n |
	index at: n add: n ].
	self assert: index pages size equals: 2.
	"another page split which should be appending"
	index at: 3000 add: 3000
]

{ #category : #tests }
SoilSkipListTest >> testVersionOneRoundtrip [

	index headerPage
		instVarNamed: #version put: 1;
		size: -1.
	1 to: 10 do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index removeKey: 4.
	self assert: index pages size equals: 1.
	self assert: index size equals: 9.

	"write it and then read it back with a new SoilSkipList"
	index writePages.
	index close.
	index := SoilSkipList new
		         path: 'sunit-skiplist';
		         open.
	self assert: index size equals: 9
]

{ #category : #tests }
SoilSkipListTest >> testVersionOneRoundtripAndCompact [

	index headerPage
		instVarNamed: #version put: 1;
		size: -1.
	1 to: 10 do: [ :n | index at: n add: (n asByteArrayOfSize: 8) ].
	index removeKey: 4.
	self assert: index pages size equals: 1.
	self assert: index size equals: 9.

	index writePages.
	index
		reopen;
		compact.
	self assert: index headerPage version equals: 3.
	self assert: (index headerPage instVarNamed: #size) equals: 9
]

{ #category : #accessing }
SoilSkipListTest >> uniqueKeys [

	^ uniqueKeys
]

{ #category : #accessing }
SoilSkipListTest >> uniqueKeys: anObject [

	uniqueKeys := anObject
]
