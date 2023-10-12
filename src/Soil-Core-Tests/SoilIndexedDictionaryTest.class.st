Class {
	#name : #SoilIndexedDictionaryTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'soil',
		'dict',
		'classToTest'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilIndexedDictionaryTest class >> testParameters [
	^ ParametrizedTestMatrix new
		addCase: { #classToTest -> SoilBTreeDictionary };
		addCase: { #classToTest -> SoilSkipListDictionary };
		yourself
]

{ #category : #accessing }
SoilIndexedDictionaryTest >> classToTest [

	^ classToTest
]

{ #category : #accessing }
SoilIndexedDictionaryTest >> classToTest: anObject [

	classToTest := anObject
]

{ #category : #accessing }
SoilIndexedDictionaryTest >> path [ 
	^ 'soil-tests'
]

{ #category : #running }
SoilIndexedDictionaryTest >> setUp [ 
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
SoilIndexedDictionaryTest >> tearDown [ 
	soil ifNotNil: [ 
		soil close ].
	super tearDown.
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAddAndRemoveExistingList [
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
SoilIndexedDictionaryTest >> testAddAndRemoveOnNewList [
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error.
	self assert: (dict at: #foo) equals: #bar.
	dict removeKey: #foo.
	self assert: dict size equals: 0
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAddToExistingEmptyList [
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
SoilIndexedDictionaryTest >> testAddToExistingNonEmptyList [
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
SoilIndexedDictionaryTest >> testAddToNewList [
  	self 
		shouldnt: [ dict at: #foo put: #bar ]
		raise: Error.
	self assert: (dict at: #foo) equals: #bar
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAt [
	dict at: #foo2 put: #bar2.
	dict at: #foo put: #bar.
	
	self assert: (dict at: #foo2) equals: #bar2.
	self should: [dict at: #ff] raise: KeyNotFound
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAtIndex [
	dict at: #foo2 put: #bar2.
	dict at: #foo put: #bar.
	
	self assert: (dict atIndex: 1) equals: #bar2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFirst [
	dict at: #foo2 put: #bar2.
	dict at: #foo put: #bar.
	
	"first in key order"
	self assert: dict first equals: #bar.
	self assert: (dict first: 1) first equals: #bar.
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFirstAssociation [
	dict at: #foo2 put: #bar2.
	dict at: #foo put: #bar.
	
	"firstAssocation in key order"
	self assert: dict firstAssociation equals: #foo->#bar.
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFirstAssociationWithSingleRemovedItem [ 
	
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict firstAssociation equals: nil
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFirstAssociationWithTransaction [
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
	self assert: tx2 root firstAssociation equals: 1->#one.

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFirstWithSingleRemovedItem [ 
	
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict first equals: nil
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFirstWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #foo2 put: #two.
	dict at: #foo put: #one.
	self assert: dict first equals: #one.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test first"
	self assert: tx2 root first equals: #one. 
	self assert: (tx2 root first: 2) second equals: #two

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testIsEmpty [
	self assert: dict isEmpty.
	dict at: #foo put: #bar.
	self deny: dict isEmpty
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLast [
	dict at: #foo2 put: #bar2.
	dict at: #foo put: #bar.
	
	"last in key order"
	self assert: dict last equals: #bar2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastAssociation [
	dict at: #foo2 put: #bar2.
	dict at: #foo put: #bar.
	
	"last association in key order"
	self assert: dict lastAssociation equals:  #foo2->#bar2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastAssociationWithSingleRemovedItem [ 
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict lastAssociation equals: nil
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastAssociationWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 2 put: #two.
	dict at: 1 put: #one.
	
	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last, not: key order"
	self assert: tx2 root lastAssociation equals: 2->#two
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastWithSingleRemovedItem [ 
	dict at: #foo put: #bar.
	dict removeKey: #foo.
	self assert: dict last equals: nil
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 2 put: #two.
	dict at: 1 put: #one.

	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last, note: keyorder"
	self assert: tx2 root last equals: #two
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastWithTransactionRemoveLast [
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
SoilIndexedDictionaryTest >> testNextAfter [
	dict at: 1 put: #bar.
	dict at: 2 put: #bar2.

	self assert:( dict nextAfter: 1) equals: #bar2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testNextAfterWithTransaction [
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
SoilIndexedDictionaryTest >> testRemoveKey [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.
	
	dict removeKey: #foo.
	self assert: dict size equals: 1.
	
	self should: [ dict removeKey: #blah ] raise: KeyNotFound
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testSecond [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict second equals: #bar2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testSecondWithTransaction [
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
	self assert: tx2 root second equals: #two
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testSize [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: dict size equals: 2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testSizeWithTransaction [
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
	self assert: tx2 root size equals: 2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testValues [
	dict at: #foo put: #bar.
	dict at: #foo2 put: #bar2.

	self assert: (dict values includes: 'bar').
	self assert: (dict values includes: 'bar2')
]
