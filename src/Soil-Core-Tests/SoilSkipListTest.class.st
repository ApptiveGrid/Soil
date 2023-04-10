Class {
	#name : #SoilSkipListTest,
	#superclass : #TestCase,
	#instVars : [
		'skipList'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
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
	super tearDown.
	skipList ifNotNil: [ 
		skipList close ]
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflow [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity - 2.
	1 to: capacity do: [ :n | 
		skipList at: n  put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: capacity + 1 put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 128.
	self assert: page items first key equals: 128.
	self assert: page items last key asByteArray equals: #[ 255 255 255 255 255 255 255 255 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetween [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity - 2.
	1 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (capacity / 2) floor put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 255.
	self assert: (page items at: (capacity / 2) floor) key equals: 125
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverflowing [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity - 2.
	1 to: capacity * 2 by: 2 do: [ :n | 
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: 32 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 127.
	self assert: (page items first) key equals: 255.
	self assert: (page items last) key asByteArray equals: #[ 255 255 255 255 255 255 255 255 ].
	skipList writePages 
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverwriting [
	
	| page capacity |
	capacity := skipList firstPage itemCapacity - 2.
	1 to: capacity * 2 by: 2 do: [ :n | 
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: 31 put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 255.
	self assert: (page items at: 17) value equals: #[ 8 7 6 5 4 3 2 1 ]
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
	self assert: page numberOfItems equals: 64.
	self assert: page items last key asByteArray equals: #[ 255 255 255 255 255 255 255 255 ]
]

{ #category : #tests }
SoilSkipListTest >> testAtIndex [
	| value |
	1 to: 200 do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	value := skipList atIndex: 133. 
	self assert: value equals: #[ 1 2 3 4 5 6 7 8 ]
]

{ #category : #tests }
SoilSkipListTest >> testCreation [
	self assert: skipList pages size equals: 1
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
SoilSkipListTest >> testIteratorDo [
	
	| capacity col |
	capacity := skipList firstPage itemCapacity.
	skipList at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 2.
	col := OrderedCollection new.
	skipList newIterator do: [ :item | col add: item ].
	self assert: col first equals: #[ 8 7 6 5 4 3 2 1 ].
	self assert: col size equals: capacity
]

{ #category : #tests }
SoilSkipListTest >> testIteratorFindAndNext [
	
	| capacity iterator value |
	capacity := skipList firstPage itemCapacity * 2.
	1 to: capacity do: [ :n |
		skipList at: n put: (n asByteArrayOfSize: 8) ].
	self assert: skipList pages size equals: 4.
	iterator := skipList newIterator.
	value := iterator
		find: 222;
		next.
	self assert: value equals: (223 asByteArrayOfSize: 8)
]

{ #category : #tests }
SoilSkipListTest >> testIteratorFirst [
	
	| capacity first |
	capacity := skipList firstPage itemCapacity * 2.
	skipList at: 1 put: #[ 8 7 6 5 4 3 2 1 ].
	2 to: capacity do: [ :n |
		skipList at: n put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 4.
	first := skipList newIterator first.
	self assert: first equals: #[ 8 7 6 5 4 3 2 1 ]
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
	self assert: page numberOfItems equals: 3.
	self assert: page items second key equals: (#foo asSkipListKeyOfSize: 8) asInteger
]
