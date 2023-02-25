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
		maxLevel: 4;
		keySize: 8;
		path: 'sunit-skiplist';
		destroy;
		initializeList
		
]

{ #category : #tests }
SoilSkipListTest >> testAddFirstOverflow [
	
	| page |
	1 to: 54 do: [ :n | 
		skipList at: n asString put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (55 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageRegistry pageAt: 2.
	self assert: page numberOfItems equals: 28.
	self assert: page items first key equals: 12856
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetween [
	
	| page |
	1 to: 62 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (32 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageRegistry pageAt: 1.
	self assert: page numberOfItems equals: 34.
	self assert: (page items at: 18) key equals: 13106
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverflowing [
	
	| page |
	1 to: 108 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (32 asString asSkipListKeyOfSize: 8) put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageRegistry pageAt: 2.
	self assert: page numberOfItems equals: 28.
	self assert: (page items first) key equals: 13621.
	skipList writePages 
]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverflowingTwice [
	
	| page |
	2 to: 167 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 2.
	skipList at: (1 asString asSkipListKeyOfSize: 8) put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 2.
	page := skipList pageRegistry pageAt: 2.
	self assert: page numberOfItems equals: 56.
	self assert: (page items first) key equals: 13622.

]

{ #category : #tests }
SoilSkipListTest >> testAddInBetweenOverwriting [
	
	| page |
	1 to: 62 by: 2 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (31 asString asSkipListKeyOfSize: 8) put: #[ 8 7 6 5 4 3 2 1 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageRegistry pageAt: 1.
	self assert: page numberOfItems equals: 34.
	self assert: (page items at: 18) value equals: #[ 8 7 6 5 4 3 2 1 ]
]

{ #category : #tests }
SoilSkipListTest >> testAddLastFitting [
	
	| page |
	1 to: 27 do: [ :n | 
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	self assert: skipList pages size equals: 1.
	skipList at: (28 asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ].
	self assert: skipList pages size equals: 1.
	page := skipList pageRegistry pageAt: 1.
	self assert: page numberOfItems equals: 30.
	self assert: page items last key equals: #[ 255 255 255 255 255 255 255 255 ]
]

{ #category : #tests }
SoilSkipListTest >> testCreation [
	self assert: skipList pageRegistry pages size equals: 1
]

{ #category : #tests }
SoilSkipListTest >> testMorePages [
	1 to: 200 do: [ :n |
		skipList at: (n asString asSkipListKeyOfSize: 8) put: #[ 1 2 3 4 5 6 7 8 ] ].
	skipList writePages.
	self assert: skipList pageRegistry pages size equals: 7
]

{ #category : #tests }
SoilSkipListTest >> testPageAddFirst [
	
	| page |
	skipList at: #foo put: #[ 1 2 3 4 5 6 7 8 ].
	skipList writePages.
	self assert: skipList pageRegistry pages size equals: 1.
	page := skipList firstPage.
	self assert: page numberOfItems equals: 3.
	self assert: page items second key equals: (#foo asSkipListKeyOfSize: 8) asInteger
]
