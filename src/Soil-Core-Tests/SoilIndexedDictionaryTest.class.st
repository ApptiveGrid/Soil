Class {
	#name : #SoilIndexedDictionaryTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'soil',
		'dict',
		'backend'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #'building suites' }
SoilIndexedDictionaryTest class >> testParameters [
	^ ParametrizedTestMatrix new
		addCase: { #backend -> SoilSkipList };
		addCase: { #backend -> SoilBTree };
		yourself
]

{ #category : #accessing }
SoilIndexedDictionaryTest >> backend [

	^ backend
]

{ #category : #accessing }
SoilIndexedDictionaryTest >> backend: anObject [

	backend := anObject
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
	dict := (SoilIndexedDictionary newWithBackend: backend)
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
	self assert: tx3 root size equals: 0

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAddRandom [
	| tx numEntries entries result |
	tx := soil newTransaction.
	tx root: dict.
	"just some random adding and checking that we can find it, configured to create lots of pages"
	
	numEntries := 1000.
	entries := Set new: numEntries.
	
	numEntries timesRepeat: [ | toAdd |
		toAdd := (numEntries*20) atRandom.
		entries add: toAdd.
		dict at: toAdd  put: toAdd asDummySoilObjectId].
	
	"check size"
	self assert: dict size equals: entries size.
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (dict at: each ) equals: each asDummySoilObjectId].
	
	"iterate index, all should be in entries"
	
	result := OrderedCollection new.
	"we use do: to iterate over the index"
	dict do: [ :each |
		result add: each].
	
	entries := (entries collect: #asDummySoilObjectId).
	result do: [ :each | self assert: (entries includes: each) ].
	
	dict reverseDo: [ :each |
		result add: each].
	result do: [ :each | self assert: (entries includes: each) ].
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAddRandomRemove [
	| tx numEntries entries removed numRemoved|
	tx := soil newTransaction.
	tx root: dict.
	"just some random adding/removing and checking state after"
	
	numEntries := 1000.
	entries := Set new: numEntries.
	
	numEntries timesRepeat: [ | toAdd |
		toAdd := (numEntries*20) atRandom.
		entries add: toAdd.
		dict at: toAdd  put:  (toAdd asByteArrayOfSize: 8) ].
	
	"check size"
	self assert: dict size equals: entries size.
	
	"can we find all the keys we added?"
	entries do: [:each | self assert: (dict at: each ) equals:  (each asByteArrayOfSize: 8)].
	
	"iterate index, all should be in entries"
	dict do: [:each | self assert: each equals: (each asByteArrayOfSize: 8)].
	dict reverseDo: [:each | self assert: each equals: (each asByteArrayOfSize: 8)].
	
	"we remove half randomly"
	numRemoved := numEntries quo: 2.
	removed := Set new: numRemoved.
	numRemoved timesRepeat: [ | toRemove |
			toRemove := entries atRandom.
			(removed includes: toRemove) ifFalse: [  
				removed add: toRemove.
				dict removeKey: toRemove]].
		
	"can we find all the keys that should still be there?"
	(entries copyWithoutAll: removed) do: [:each | self assert: (dict at: each ) equals: (each asByteArrayOfSize: 8)].
	
	"all the removed ones are gone"
	removed do: [ :each | self assert: (dict at: each ifAbsent: [ true ]) ]
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
	"create indexed dictionary with a key ...
	... and persist it"
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
SoilIndexedDictionaryTest >> testAfterReopen [
	"test that we can close and re-open the database"
 	| tx |
 	tx := soil newTransaction.
 	tx root: dict.
 	tx commit.
 	"Open a fresh Soil instance, so index structures are not cached"
 	soil close. soil open.
 	tx := soil newTransaction.
 	"Getting the values, before doing #at:put: yielded index pages with nil pageSize"
 	tx root values.
 	tx root at: 'abc' asByteArray put: #one.
 	self
 		shouldnt: [ tx commit ]
 		raise: Error
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testAtIfAbsent [
	| return tx |
	tx := soil newTransaction.
	tx root: dict.
	return := dict at: 1 ifAbsent: [ #missing ].
	self assert: return equals:  #missing
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

{ #category : #'tests - concurrent' }
SoilIndexedDictionaryTest >> testConcurrentAddKey [
	| tx1 tx2 tx3 tx4 |
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
	self assert: (tx2 root at: #two ifAbsent: [ #notfound ]) equals: #notfound.
	
	"new transactions sees both"
	tx4 := soil newTransaction.
	self assert: (tx4 root at: #one) equals: #onevalue.
	self assert: (tx4 root at: #two) equals: #twovalue.
	
]

{ #category : #'tests - concurrent' }
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

{ #category : #'tests - concurrent' }
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

{ #category : #'tests - concurrent' }
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

{ #category : #'tests - concurrent' }
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
	tx2 root do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 2.
	
	tx2 root removeKey: #one.
	
	counter := 0.
	tx2 root do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 1.
	
	tx2 commit.
	"in tx1 the key is not removed, do: correcty uses the restorValue"
	counter := 0.
	tx1 root  do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 2.
	
	"we can remove the key in tx1, were it still exists"
	tx1 root removeKey: #one.
	counter := 0.
	tx1 root do: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 1.
	
	
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
SoilIndexedDictionaryTest >> testFirstWithTransactionRemoved [
	| tx tx1 tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	
	"open a two transactions ..."
	tx1 := soil newTransaction.
	tx2 := soil newTransaction.
	tx2 root removeKey: #one.
	tx2 commit.
	"in tx1 the removed one is not removed"
	self assert: tx1 root first equals: #onevalue.

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
SoilIndexedDictionaryTest >> testFreePageAfterReopen [
	| tx tx2 index indexManager tx3 |
	indexManager := soil objectRepository firstSegment indexManager.
	tx := soil newTransaction.
	tx root: dict.
	1 to: 1300 do: [ :n | dict at: n put: n asString ].
	tx commit.
		
	"open a second transaction ..."
	tx2 := soil newTransaction.
	300 to: 1100 do: [ :n | tx2 root removeKey: n ].
	tx2 commit.
	index := indexManager indexes anyOne.
	self deny: index headerPage firstFreePageIndex identicalTo: 0.

	"even after close and reopen of Soil, this still works"
	soil 
		close; 
		reopen.
	tx3 := soil newTransaction.
	"reloaded index has free page"
	self deny: tx3 root index  headerPage firstFreePageIndex identicalTo: 0.
	tx3 commit
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFreePageNotSavedRegression [
	| tx blockTx iterator |
	tx := soil newTransaction.
	tx root: dict.
	"fill a 5 pages"
	1 to: 1000 do: [ :n |
		tx root at: n put: n asString ].
	tx commit.
	"open transaction that blocks page cleanup"
   blockTx := soil newTransaction.
	tx := soil newTransaction.
	"remove all items of page #2 and almost all from page #3"
	224 to: 672 do: [ :n |
		tx root removeKey: n ].
	tx commit.
	"remove blocking transaction"
	blockTx abort.
	"now close database so that the pages are written uncleaned"
	soil close; open.
	tx := soil newTransaction.
	"now remove the remaining items of page#3 which make page #3
	dirty"
	673 to: 676 do: [ :n |
		tx root removeKey: n ].
	"now page#3 will be written, page #2 is only altered in memory 
	without going to disk"
	tx commit.
	"close the database and that makes the page #2 state get lost"
	soil close; open.
	tx := soil newTransaction.
	"on next access before the fix we bumped into a free page appearing
	in the items page chain"
	iterator := tx root newIterator.
	self shouldnt: [ 1 to: 700 do: [ :n| iterator basicNextAssociation ] ]
		raise: Error.

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFreePageReuse [
	| tx tx2 index indexManager tx3 |
	tx := soil newTransaction.
	tx root: dict.
	1 to: 1300 do: [ :n | dict at: n put: n asString ].
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	300 to: 1200 do: [ :n | tx2 root removeKey: n ].
	tx2 commit.
	tx3 := soil newTransaction.
	300 to: 1200 do: [ :n | tx3 root at: n put: n asString ].
	tx3 commit.
	indexManager := soil objectRepository firstSegment indexManager.
	index := indexManager indexes anyOne.
	self assert: index headerPage firstFreePageIndex identicalTo: 0.
	self assert: index firstFreePage isNil

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testFreePages [ 
	| tx tx2 index indexManager |
	indexManager := soil objectRepository firstSegment indexManager.
	tx := soil newTransaction.
	tx root: dict.
	1 to: 1300 do: [ :n | dict at: n put: n asString ].
	tx commit.
	(backend = SoilBTree) 
		ifTrue:  [ self assert: indexManager indexes anyOne pages size equals: 12]
		ifFalse: [ self assert: indexManager indexes anyOne pages size equals: 6].
		
	"open a second transaction ..."
	tx2 := soil newTransaction.
	300 to: 1100 do: [ :n | tx2 root removeKey: n ].
	tx2 commit.
	index := indexManager indexes anyOne.
	self deny: index headerPage firstFreePageIndex identicalTo: 0.
	(backend = SoilBTree) 
		ifTrue:  [ self assert: index firstFreePage pageIndexes size equals: 5 ]
		ifFalse: [ self assert: index firstFreePage pageIndexes size equals: 1 ]
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
	self assert: tx2 root last equals: #twovalue.
	self assert: (tx2 root last: 2) second equals: #twovalue
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
SoilIndexedDictionaryTest >> testLastWithTransactionRemoved [
	| tx tx1 tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	
	"open a two transactions ..."
	tx1 := soil newTransaction.
	tx2 := soil newTransaction.
	tx2 root removeKey: #two.
	tx2 commit.
	"in tx1 the removed one is not removed"
	self assert: tx1 root last equals: #twovalue.

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testNextAfter [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: dict.
	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"and test last"
	self assert: (tx2 root nextAfter: #one) equals: #twovalue.
	"test #nextAssociationAfter: on the iterator here, too"
	self assert: (tx2 root newIterator nextAssociationAfter: #one) value equals: #twovalue
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testNextCloseTo [
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
SoilIndexedDictionaryTest >> testRecoverAddedKeys [
	| tx tx2 blockedTx |
	"We test that added keys are not shown in a prior transaction"
	tx := soil newTransaction.
	tx root: dict.
	dict 
		at: #testkey1 put: 'one';
		at: #testkey2 put: 'two';
		at: #testkey3 put: 'three'.
	tx commit.
	
	blockedTx := soil newTransaction.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	self assert: (tx2 root at: #testkey1) equals: 'one'.
	tx2 root 
		at: #testkey4 put: 'four'.
	tx2 commit.
	"and test last, note: keyorder"
	self assert: (blockedTx root at: #testkey1) equals: 'one'.
	self assert: (blockedTx root at: #testkey4 ifAbsent: #notThere) equals: #notThere

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testRecoverMulitpleDuplicateKeys [
	| tx tx2 blockedTx values tx3 |
	tx := soil newTransaction.
	dict index allowDuplicateKeys.
	tx root: dict.
	dict 
		at: #testkey put: 'one';
		at: #testkey put: 'two';
		at: #testkey put: 'three'.
	values := dict at: #testkey.
	self assert: values class equals: OrderedCollection.
	self assert: values size equals: 3.
	tx commit.
	
	blockedTx := soil newTransaction.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	values := tx2 root at: #testkey.
		
	self assert: values class equals: OrderedCollection.
	self assert: values size equals: 3.
	tx2 root 
		removeKey: #testkey value: values first;
		removeKey: #testkey value: values second;
		removeKey: #testkey value: values third. 
	tx2 root at: #testkey put: 'four'.
	tx2 commit.
	"and test last, note: keyorder"
	self assert: (blockedTx root at: #testkey) size equals: 3.
	self assertCollection: ((blockedTx root at: #testkey) collect: #yourself) hasSameElements: #('one' 'two' 'three').
	
	"we can now start new transaction and see the state as commited in tx2"
	tx3 := soil newTransaction.
	values := tx3 root at: #testkey.
	self assert: values class equals: OrderedCollection.
	self assert: values size equals: 1.
	self assert: values first equals: 'four'
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testRecoverMulitpleDuplicateKeysAdd [
	| tx tx2 tx3 blockedTx values |
	tx := soil newTransaction.
	dict index allowDuplicateKeys.
	tx root: dict.
	dict 
		at: #testkey put: 'one';
		at: #testkey put: 'two';
		at: #testkey put: 'three'.
	values := dict at: #testkey.
	self assert: values class equals: OrderedCollection.
	self assert: values size equals: 3.
	tx commit.
	
	blockedTx := soil newTransaction.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	values := tx2 root at: #testkey.
		
	self assert: values class equals: OrderedCollection.
	self assert: values size equals: 3.
	tx2 root at: #testkey put: 'four'.
	tx2 commit.
	"and test last, note: keyorder"
	self assert: (blockedTx root at: #testkey) size equals: 3.
	self assertCollection: ((blockedTx root at: #testkey) collect: #yourself) hasSameElements: #('one' 'two' 'three').
	
	"we can now start new transaction and see the state as commited in tx2"
	tx3 := soil newTransaction.
	values := tx3 root at: #testkey.
	self assert: values class equals: OrderedCollection.
	self assertCollection: (values collect: #yourself) hasSameElements: #('one' 'two' 'three' 'four').
	self assert: values size equals: 4
]

{ #category : #tests }
SoilIndexedDictionaryTest >> testRemoveKey [
	| tx tx2 tag return |
	tx := soil newTransaction.
	tx root: dict.

	dict at: #one put: #onevalue.
	dict at: #two put: #twovalue.
	tx commit.
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"remove the key"
	return := tx2 root removeKey: #two.
	self assert: tx2 root size equals: 1.
	self assert: return equals: #twovalue.
	"remove again to test absent case"
	tag := false.
	tx2 root removeKey: #three ifAbsent: [ tag := true ].
	self assert: tag.
	"remove again to test absent case with already removed key"
	tag := false.
	tx2 root removeKey: #two ifAbsent: [ tag := true ].
	self assert: tag

]

{ #category : #'tests - concurrent' }
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
SoilIndexedDictionaryTest >> testRemovePagesConcurrent [
	| tx tx2 index indexManager tx3 tx4 |
	indexManager := soil objectRepository firstSegment indexManager.
	tx := soil newTransaction.
	tx root: dict.
	1 to: 1000 do: [ :n | dict at: n put: n asString ].
	tx commit.
	self assert: indexManager indexes size equals: 1.
	index := indexManager indexes anyOne.
	"open more transactions ..."
	tx2 := soil newTransaction.
	tx3 := soil newTransaction.
	tx4 := soil newTransaction.
	300 to: 500 do: [ :n | tx2 root removeKey: n ].
	tx2 commit.
	(backend = SoilBTree) 
		ifTrue: [self assert: (index pages select: #needsCleanup) size equals: 3]
		ifFalse: [self assert: (index pages select: #needsCleanup) size equals: 2].
	501 to: 700 do: [ :n | tx3 root removeKey: n ].
	tx3 commit.
	(backend = SoilBTree) 
		ifTrue: [self assert: (index pages select: #needsCleanup) size equals: 5]
		ifFalse: [self assert: (index pages select: #needsCleanup) size equals: 3].
	
	701 to: 702 do: [ :n | tx4 root removeKey: n ].
	tx4 commit.
	self assert: indexManager dirtyIndexes size equals: 0.
	self assert: (index pages select: #needsCleanup) size equals: 0.

	

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testRemovePagesSequential [
	| tx tx2 index indexManager |
	
	tx := soil newTransaction.
	tx root: dict.
	1 to: 1000 do: [ :n | dict at: n put: n asString ].
	tx commit.
	
	"open a second transaction ..."
	tx2 := soil newTransaction.
	"we remove all keys from one page to make it empty"
	(backend = SoilBTree) 
		ifTrue: [339 to: 451 do: [ :n | tx2 root removeKey: n ]]
		ifFalse: [ 300 to: 700 do: [ :n | tx2 root removeKey: n ]].
	tx2 commit.
	indexManager := soil objectRepository firstSegment indexManager.
	index := indexManager indexes anyOne.
	self assert: index dirtyPages size equals: 0.
	self assert: indexManager dirtyIndexes size equals: 0.
	self assert: (index pages select: #needsWrite) size equals: ((backend = SoilBTree) ifTrue: [1] ifFalse: [0])
	

]

{ #category : #tests }
SoilIndexedDictionaryTest >> testReverseDo [
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
	tx2 root reverseDo: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 2.
	
	tx2 root removeKey: #one.
	
	counter := 0.
	tx2 root reverseDo: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 1.
	
	tx2 commit.
	"in tx1 the key is not removed, do: correcty uses the restorValue"
	counter := 0.
	tx1 root reverseDo: [ :each |
		self assert: (each beginsWith: 'bar').
		counter := counter + 1].
	self assert: counter equals: 2
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
SoilIndexedDictionaryTest >> testSize [
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
SoilIndexedDictionaryTest >> testValues [
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
