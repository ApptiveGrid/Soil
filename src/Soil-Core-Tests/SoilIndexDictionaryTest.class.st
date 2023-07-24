Class {
	#name : #SoilIndexDictionaryTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'soil',
		'dict',
		'classToTest'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilIndexDictionaryTest class >> testParameters [
	^ ParametrizedTestMatrix new
		addCase: { #classToTest -> SoilBTreeDictionary };
		addCase: { #classToTest -> SoilSkipListDictionary };
		yourself
]

{ #category : #accessing }
SoilIndexDictionaryTest >> classToTest [

	^ classToTest
]

{ #category : #accessing }
SoilIndexDictionaryTest >> classToTest: anObject [

	classToTest := anObject
]

{ #category : #accessing }
SoilIndexDictionaryTest >> path [ 
	^ 'soil-tests'
]

{ #category : #running }
SoilIndexDictionaryTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem.
	dict := classToTest new
		keySize: 10;
		maxLevel: 8; "ignored for BTree"
		yourself
]

{ #category : #running }
SoilIndexDictionaryTest >> tearDown [ 
	soil ifNotNil: [ 
		soil close ].
	super tearDown.
]

{ #category : #tests }
SoilIndexDictionaryTest >> testAddAndRemoveExistingList [
	| tx tx2 tx3 |
	"create skip list dictionary with a key ..."
	"... and persist it"
	tx := soil newTransaction.
	tx root: dict.
	dict at: #foo put: #one.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"... and remove the key from the persisted list"
	tx2 root
		removeKey: #foo.
	tx2 commit.
	tx3 := soil newTransaction.
	self assert: (tx3 root at: #foo ifAbsent: [ nil ]) equals: nil.

]

{ #category : #tests }
SoilIndexDictionaryTest >> testAddAndRemoveOnNewList [
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error.
	self assert: (dict at: #foo) equals: #bar.
	dict removeKey: #foo.
	self assert: dict size equals: 0
]

{ #category : #tests }
SoilIndexDictionaryTest >> testAddToExistingEmptyList [
	| tx tx2 tx3 tx4 |
	"create emtpy skip list dictionary ..."
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
SoilIndexDictionaryTest >> testAddToExistingNonEmptyList [
	|  tx tx2 tx3 tx4 |
	"create skip list dictionary with a key ..."
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
	self assert: (tx4 root at: #foo) equals: #bar.	
]

{ #category : #tests }
SoilIndexDictionaryTest >> testAddToNewList [
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error.
	self assert: (dict at: #foo) equals: #bar
]

{ #category : #tests }
SoilIndexDictionaryTest >> testFirst [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict first equals: #bar.
	self assert: (dict first: 1) first equals: #bar.
]

{ #category : #tests }
SoilIndexDictionaryTest >> testFirstAssociationWithSingleRemovedItem [ 
	
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict firstAssociation equals: nil
]

{ #category : #tests }
SoilIndexDictionaryTest >> testFirstWithSingleRemovedItem [ 
	
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict first equals: nil
]

{ #category : #tests }
SoilIndexDictionaryTest >> testFirstWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: #one.
	dict at: 2 put: #two.
	self assert: dict first equals: #one.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test first"
	self assert: tx2 root first equals: #one. 
	self assert: (tx2 root first: 2) second equals: #two

]

{ #category : #tests }
SoilIndexDictionaryTest >> testIsEmpty [
	self assert: dict isEmpty.
	dict at: #foo put: #bar.
	self deny: dict isEmpty
]

{ #category : #tests }
SoilIndexDictionaryTest >> testLast [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict last equals: #bar2
]

{ #category : #tests }
SoilIndexDictionaryTest >> testLastAssociationWithSingleRemovedItem [ 
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict lastAssociation equals: nil
]

{ #category : #tests }
SoilIndexDictionaryTest >> testLastWithSingleRemovedItem [ 
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict last equals: nil
]

{ #category : #tests }
SoilIndexDictionaryTest >> testLastWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: #one.
	dict at: 2 put: #two.
	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: tx2 root last equals: #two
]

{ #category : #tests }
SoilIndexDictionaryTest >> testLastWithTransactionRemoveLast [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: #one.
	dict at: 2 put: #two.
	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	tx2 root removeKey: 2.
	"and test last"
	self assert: tx2 root last equals: #one
]

{ #category : #tests }
SoilIndexDictionaryTest >> testNextAfter [
	dict at: 1 put: #bar.
	dict at: 2 put: #bar2.

	self assert:( dict nextAfter: 1) equals: #bar2
]

{ #category : #tests }
SoilIndexDictionaryTest >> testNextAfterWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: #one.
	dict at: 2 put: #two.
	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: (tx2 root nextAfter: 1) value equals: #two
]

{ #category : #tests }
SoilIndexDictionaryTest >> testSecond [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict second equals: #bar2
]

{ #category : #tests }
SoilIndexDictionaryTest >> testSize [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict size equals: 2
]

{ #category : #tests }
SoilIndexDictionaryTest >> testValues [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: (dict values includes: 'bar').
	self assert: (dict values includes: 'bar2')
]
