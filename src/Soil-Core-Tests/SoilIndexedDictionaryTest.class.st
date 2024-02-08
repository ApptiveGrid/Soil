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
		addCase: { #classToTest -> SoilSkipListDictionary };
		addCase: { #classToTest -> SoilBTreeDictionary };
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
SoilIndexedDictionaryTest >> testAtIndexWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test atIndex:"
	self assert: (tx2 root atIndex: 1) equals: #onevalue

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testConcurrentAddKey [ 
	| tx1 tx2 tx3 |
	tx1 := soil newTransaction.
	tx1 root: dict.
	dict
		at: #one put: #onevalue.
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and add a key to 
	the dictionary which should be invisible to tx2"
	tx3 := soil newTransaction.
	tx3 root
		at: #two put: #twovalue.
	tx3 commit.
	self assert: (tx2 root at: #one) equals: #onevalue.
	self assert: (tx2 root at: #two ifAbsent: [ #notfound ]) equals: #notfound
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testConcurrentDo [
	| tx1 tx2 tx3 col |
	tx1 := soil newTransaction.
	tx1 root: dict.
	dict
		at: #one put: #onevalue;
		at: #two put: #twovalue;
		at: #three put: #threevalue;
		at: #four put: #fourvalue.
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and add a key to 
	the dictionary which should be invisible to tx2"
	tx3 := soil newTransaction.
	tx3 root
		at: #five put: #fivevalue.
	tx3 commit.
	col := OrderedCollection new.
	tx2 root do: [ :each |
		col add: each ].
	self assert: col size equals: 4.
	self assert: (col noneSatisfy: [:each | each = #fiveValue ])
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testConcurrentIsEmpty [ 
	| tx1 tx2 tx3 |
	tx1 := soil newTransaction.
	tx1 root: dict.
	dict
		at: #one put: #onevalue.
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and add a key to 
	the dictionary which should be invisible to tx2"
	tx3 := soil newTransaction.
	tx3 root removeKey: #one.
	tx3 commit.
	"invisible: tx2 still has the key"
	self deny: tx2 root isEmpty.
	self assert: tx2 root size equals: 1
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testConcurrentRemoveKey [
	| tx1 tx2 tx3 |
	tx1 := soil newTransaction.
	tx1 root: dict.
	dict
		at: #one put: #onevalue.
	tx1 commit.
	tx2 := soil newTransaction.
	"After creating tx2 we open a concurrent transaction and remove a key to 
	the dictionary which should still be visible to tx2"
	tx3 := soil newTransaction.
	tx3 root
		removeKey: #one.
	tx3 commit.
	self assert: (tx2 root at: #one) equals: #onevalue.
	self deny: tx2 root isEmpty.

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testDoWithTransAction [
	| tx tx1 tx2 counter |
	
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #bar1.
	dict at: #two put: #bar2.
	tx commit.
	"open a second transaction ..."
	tx1 := soil newTransaction.
	tx2 := soil newTransaction.

	counter := 0.
	tx2 root  do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 2.
	
	tx2 root removeKey: #one.
	
	counter := 0.
	tx2 root  do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 1.
	
	tx2 commit.
	"in tx1 the key is not removed, do: correcty uses the restorValue"
	counter := 0.
	tx1 root  do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 2
	
	
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
SoilIndexedDictionaryTest >> testFirstAssociationWithTransactionRemoved [
	| tx tx1 tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: #one.
	dict at: 2 put: #two.
	"self assert: dict last equals: #two."
	tx commit.
	
	"open a two transactions ..."
	tx1 := soil newTransaction.
	tx2 := soil newTransaction.
	tx2 root removeKey: 1.
	tx2 commit.
	"in tx1 the removed one is not removed"
	self assert: tx1 root firstAssociation equals: 1->#one.

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
SoilIndexedDictionaryTest >> testFlushIndexPages [
	| tx  capacity txn2 txn1 root1 root2 |
	tx := soil newTransaction.
	tx root: dict.
	capacity := (dict index pageAt: 1) itemCapacity.
	1 to: capacity + 1 do: [ :n | 
		dict at: n asString put: n asString ].
	tx commit.
	txn1 := soil newTransaction.
	root1 := txn1 root.
	(dict index isKindOf: SoilSkipList)
		ifTrue: [ self assert: root1 index wrapped pages size equals: 2]
		ifFalse: [self assert: root1 index wrapped pages size equals: 3].
	root1 index flushCachedPages.
	self assert: root1 index pages size equals: 0.
	txn1 abort.

	txn2 := soil newTransaction.
	root2 := txn2 root.
	self assert: root2 index pages size equals: 0.
	self assert: root2 index wrapped pages size equals: 0.
	self assert: (root2 at: '56') equals: '56'.
	txn2 abort
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testIndexCreation [ 
	| tx obj1 obj2 |
	tx := soil newTransaction.
	obj1 := Object new.
	tx makeRoot: obj1.
	obj2 := Object new.
	tx makeRoot: obj2.
	tx root: dict.
	dict 
		at: #foo put: obj1;
		at: #boo put: obj2.
	tx commit

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testIndexCreationAndRead [
	| tx obj1 obj2 tx2 |
	tx := soil newTransaction.
	obj1 := SoilTestClusterRoot new nested: 'object1'.
	tx makeRoot: obj1.
	obj2 := SoilTestClusterRoot new nested: 'object2'.
	tx makeRoot: obj2.
	tx root: dict.
	dict 
		at: #foo put: obj1;
		at: #boo put: obj2.
	tx commit.
	tx2 := soil newTransaction.
	self assert: (tx2 root at: #foo) nested equals: 'object1'.
	self assert: (tx2 root at: #boo) nested equals: 'object2'


]

{ #category : #tests }
SoilIndexedDictionaryTest >> testIsEmpty [
	| tx tx1 tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #oneValue.
	tx commit.
	"open a second transaction ..."
	tx1 := soil newTransaction.
	"and test isEmpty"
	self deny: tx1 root isEmpty.
	
	tx2 := soil newTransaction.
	tx2 root removeKey: #one.
	self assert: tx2 root size equals: 0.
	self assert: tx2 root isEmpty.
	tx2 commit.
	"still not empty in t1"
	self assert: tx1 root size equals: 1.
	self deny: tx1 root isEmpty.
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
SoilIndexedDictionaryTest >> testLastAssociationWithTransactionRemoved [
	| tx tx1 tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 1 put: #one.
	dict at: 2 put: #two.
	"self assert: dict last equals: #two."
	tx commit.
	
	"open a two transactions ..."
	tx1 := soil newTransaction.
	tx2 := soil newTransaction.
	tx2 root removeKey: 2.
	tx2 commit.
	"in tx1 the removed one is not removed"
	self assert: tx1 root lastAssociation equals: 2->#two.

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #two put: #twovalue.
	dict at: #one put: #onevalue.

	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last, note: keyorder"
	self assert: tx2 root last equals: #twovalue
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testLastWithTransactionRemoveLast [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	tx2 root removeKey: #two.
	"and test last"
	self assert: tx2 root last equals: #onevalue
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testNextAssociationAfterWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: (tx2 root nextAssociationAfter: #one) value equals: #twovalue
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testNextKeyCloseToWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: 10 put: #one.
	dict at: 20 put: #two.
	"self assert: dict last equals: #two."
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: (tx2 root nextKeyCloseTo: 15) value equals: 20
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testNextcloseToWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #'10' put: #one.
	dict at: #'20' put: #two.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test"
	self assert: (tx2 root nextCloseTo: #'5') equals: #one.
	self assert: (tx2 root nextCloseTo: #'10') equals: #one.
	self assert: (tx2 root nextCloseTo: #'11') equals: #two.
	self assert: (tx2 root nextCloseTo: #'15 ') equals: #two.
	self assert: (tx2 root nextCloseTo: #'20') equals: #two.
	"this is a bit odd, when looking with larger values we get the last one"
	self assert: (tx2 root nextCloseTo: #'100') equals: #two
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testRemoveKeyIfAbsentWithTransaction [


	| tx tx2 tag |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"remove the key"
	tx2 root removeKey: #two.
	self assert: tx2 root size equals: 1.
	"remove again to test absent case"
	tag := false.
	tx2 root removeKey: #three ifAbsent: [ tag := true ].
	self assert: tag.
	"remove again to test absent case with already removed key"
	tag := false.
	tx2 root removeKey: #two ifAbsent: [ tag := true ].
	self assert: tag.
	

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testRemoveKeyWithTwoTransactions [

	| tx tx2 |
	"the wrong assumption about concurrent modifications has been removed. This test 
	fails until we have a real way of detecting concurrent index accesses"
	self skip.
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"we create two transactions"
	tx := soil newTransaction.
	tx2 := soil newTransaction.
	"remove the key"
	tx2 root removeKey: #two.
	tx2 commit.
	"check that we can still see in the first tr"
	self assert: (tx root at: #two) equals: #twovalue.
	"but removeKey: does not see it, we can remove it without error"
	tx root removeKey: #two ifAbsent: [ self fail ].
	self assert: tx root size equals: 1.
	"but commiting it will fail, as we have commited the remove in t2"
	self should: [tx commit] raise: SoilObjectHasConcurrentChange
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testSecondWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: tx2 root second equals: #twovalue
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testSizeWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: tx2 root size equals: 2
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testValuesWithTransaction [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: tx2 root values size equals: 2.
	self assert: (tx2 root values includes: #onevalue).
	self assert: (tx2 root values includes: #twovalue)
]
