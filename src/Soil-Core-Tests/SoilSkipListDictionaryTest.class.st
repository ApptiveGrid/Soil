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
SoilSkipListDictionaryTest >> testAddToExistingEmptyList [
	| dict tx tx2 tx3 tx4 |
	"create emtpy skip list dictionary ..."
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	"... and persist it"
	tx := soil newTransaction.
	tx root: dict.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"... add a key but do not commit"
	tx2 root
		at: #foo put: #bar.
	"open third transaction and try to read the added key. As tx2
	is not committed the key should not be visible here"
	tx3 := soil newTransaction.
	self deny: (tx3 root at: #foo ifAbsent: [#nope]) equals: #bar.
	"now commit the second transaction"
	tx2 commit.
	"try to read the key again. The key should not be visibile because
	the readVersion is older than the value for that key"
	self deny: (tx3 root at: #foo ifAbsent: [#nope]) equals: #bar.
	tx3 abort.	
	tx4 := soil newTransaction.
	self assert: (tx4 root at: #foo) equals: #bar
	
		
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToExistingNonEmptyList [
	| dict tx tx2 tx3 tx4 |
	"create skip list dictionary with a key ..."
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
	"... and persist it"
	tx := soil newTransaction.
	tx root: dict.
	dict at: #foo put: #one.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"... add a key but do not commit"
	tx2 root
		at: #foo put: #bar.
	"open third transaction and try to read the added key. As tx2
	is not committed the key should be the old one"
	tx3 := soil newTransaction.
	self assert: (tx3 root at: #foo) equals: #one.
	"now commit the second transaction"
	tx2 commit.
	"try to read the key again. The key should not be visibile because
	the readVersion is older than the value for that key"
	self assert: (tx3 root at: #foo) equals: #one.
	tx3 abort.	
	tx4 := soil newTransaction.
	self assert: (tx4 root at: #foo) equals: #bar
	
		
]

{ #category : #tests }
SoilSkipListDictionaryTest >> testAddToNewList [
	| dict |
	dict := SoilSkipListDictionary new
		keySize: 10;
		maxLevel: 8;
		yourself.
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error
]
