Class {
	#name : #SoilSkipListDictionaryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilSkipListDictionaryTest >> path [ 
	^ 'soil-tests'
]

{ #category : #initialization }
SoilSkipListDictionaryTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilSkipListDictionaryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToExistingList [
	| dict tx tx2 tx3 root tx4 |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx := soil newTransaction.
	tx root: dict.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root
		at: #foo put: #bar.
	tx3 := soil newTransaction.
	self deny: (tx3 root at: #foo ifAbsent: [#nope]) equals: #bar.
	tx3 abort.
	tx2 commit.
	
	tx4 := soil newTransaction.
	root := tx4 root.
	self assert: (root at: #foo) equals: #bar
	
		
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToNewList [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
  	dict
		at: #foo put: #bar.
		
]
