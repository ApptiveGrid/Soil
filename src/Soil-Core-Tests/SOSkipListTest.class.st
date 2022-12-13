Class {
	#name : #SOSkipListTest,
	#superclass : #TestCase,
	#instVars : [
		'skipList'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #initialization }
SOSkipListTest >> setUp [ 
	super setUp.
	skipList := SOPersistentSkipList new 
		maxLevel: 4;
		keySize: 8;
		path: 'sunit-skiplist';
		destroy;
		initializeList
		
]

{ #category : #tests }
SOSkipListTest >> testAddFirstOverflow [
	
	| page |
	1 to: 62 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (63 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: page items first key equals: #[ 255 255 255 255 255 255 255 255 ]
]

{ #category : #tests }
SOSkipListTest >> testAddInBetween [
	
	| page |
	1 to: 62 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (32 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 34.
	self assert: (page items at: 18) key equals: (32 asString asSkipListKeyOfSize: 8)
]

{ #category : #tests }
SOSkipListTest >> testAddInBetweenOverflowing [
	
	| page |
	1 to: 124 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (32 asString asSkipListKeyOfSize: 8) put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageAt: 2.
	self assert: page numberOfItems equals: 1.
	self assert: (page items first) key equals: #[ 255 255 255 255 255 255 255 255 ].
	skipList writePages 
]

{ #category : #tests }
SOSkipListTest >> testAddInBetweenOverflowingTwice [
	
	| page |
	2 to: 253 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 2.
	skipList at: (1 asString asSkipListKeyOfSize: 8) put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 3.
	page := skipList pageAt: 3.
	self assert: page numberOfItems equals: 1.
	self assert: (page items first) key equals: #[ 255 255 255 255 255 255 255 255 ].

]

{ #category : #tests }
SOSkipListTest >> testAddInBetweenOverwriting [
	
	| page |
	1 to: 62 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (31 asString asSkipListKeyOfSize: 8) put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 33.
	self assert: (page items at: 17) value equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SOSkipListTest >> testAddLastFitting [
	
	| page |
	1 to: 61 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (63 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageAt: 1.
	self assert: page numberOfItems equals: 64.
	self assert: page items last key equals: #[ 255 255 255 255 255 255 255 255 ]
]

{ #category : #tests }
SOSkipListTest >> testCreation [
	self assert: skipList pages size equals: 1
]

{ #category : #tests }
SOSkipListTest >> testMorePages [
	1 to: 200 do: [ :n |
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList writePages.
	self assert: skipList pages size equals: 4
]

{ #category : #tests }
SOSkipListTest >> testPageAddFirst [
	
	| page |
	skipList at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	skipList writePages.
	self assert: skipList pages size equals: 1.
	page := skipList firstPage.
	self assert: page numberOfItems equals: 3.
	self assert: page items second key equals: (#foo asSkipListKeyOfSize: 8)
]
