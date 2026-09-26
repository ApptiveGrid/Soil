Class {
	#name : #SoilPersistentDictionaryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #accessing }
SoilPersistentDictionaryTest >> path [ 
	^ 'soil-tests-dict'
]

{ #category : #initialization }
SoilPersistentDictionaryTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : #private }
SoilPersistentDictionaryTest >> recordsHoldingValuesWrittenInPlace [
	"the records of the data segment whose object the serializer would have written in place
	- nothing can point at such a record, see Object>>soilIsWrittenByValue"
	| tx segment found |
	tx := soil newTransaction.
	segment := soil objectRepository segmentAt: 1.
	found := (1 to: segment lastObjectIndex) select: [ :index |
		(tx objectWithId: (SoilObjectId segment: 1 index: index)) soilIsWrittenByValue ].
	tx abort.
	^ found
]

{ #category : #running }
SoilPersistentDictionaryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAValueWrittenInPlaceGetsNoRecordOfItsOwn [
	"#at:put: made a cluster root of every value it was handed. A symbol, nil, true or a
	small integer is written into the dictionary itself all the same, so each got a record
	nothing points at - one per #at:put:, on every commit that set one"
	| tx |
	tx := soil newTransaction.
	tx root: SoilPersistentDictionary new.
	tx commit.
	tx := soil newTransaction.
	tx root
		at: #integer put: 1;
		at: #nil put: nil;
		at: #symbol put: #aSymbol;
		at: #true put: true.
	tx commit.
	self assert: self recordsHoldingValuesWrittenInPlace isEmpty.
	tx := soil newTransaction.
	self assert: (tx root at: #integer) equals: 1.
	self assert: (tx root at: #nil) isNil.
	self assert: (tx root at: #symbol) equals: #aSymbol.
	self assert: (tx root at: #true).
	tx abort
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testADictionaryWrittenWithoutATransactionGivesItsSymbolsNoRecord [
	"a dictionary that does not know its transaction yet - built outside one, or read and
	copied - makes its values cluster roots when it is written, and a symbol went the same
	way as the string next to it"
	| tx dictionary |
	dictionary := SoilPersistentDictionary new.
	dictionary
		at: #symbol put: #aSymbol;
		at: #string put: 'a string'.
	tx := soil newTransaction.
	tx root: (Dictionary new at: #dictionary put: dictionary; yourself).
	tx commit.
	self assert: self recordsHoldingValuesWrittenInPlace isEmpty.
	tx := soil newTransaction.
	self assert: ((tx root at: #dictionary) at: #symbol) equals: #aSymbol.
	self assert: ((tx root at: #dictionary) at: #string) equals: 'a string'.
	tx abort
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAdd [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	
	dict add: (#test -> 'string').
	transaction commit.
		
	self assert: (dict at: #test) equals: 'string'
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAddValueWithoutBeingRoot [

	| dict transaction root txn2 |
	transaction := soil newTransaction.
	root := Dictionary new.
	transaction root: root.
	dict := SoilPersistentDictionary new.
	root at: #dict put: dict.
	dict add: (#test -> 'string').
	transaction commit.
	
	txn2 := soil newTransaction.	
	self assert: ((txn2 root at: #dict) at: #test) equals: 'string'.
	txn2 abort.
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAnyOne [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	
	dict add: (#test -> 'string').
	dict add: (#test2 -> 'string').
	transaction commit.
		
	self assert: (dict anyOne value) equals: 'string'.
	


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAt [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	
	dict add: (#test -> 'string').
	transaction commit.
		
	self assert: (dict at: #test) equals: 'string'.
	


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAtIfAbsent [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	transaction commit.
		
	self assert: (dict at: #test2 ifAbsent: [#missing]) equals: #missing
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAtIfAbsentPut [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	self assert: (dict at: #test2 ifAbsentPut: [#missing]) equals: #missing.
	self assert: (dict at: #test2) equals: #missing.
	transaction makeRoot: dict.
	transaction commit.


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAtIfPresentIfAbsent [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	dict at: #test1 put: 1.
	transaction makeRoot: dict.
	transaction commit.
		
	self assert: (dict at: #test2 ifPresent: [#present] ifAbsent: [#missing]) equals: #missing.
	self assert: (dict at: #test1 ifPresent: [:pr | #present] ifAbsent: [#missing]) equals: #present.
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAtPut [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	transaction commit.
		
	self assert: (dict at: #test) equals: 'string'.
	


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testCollect [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	transaction commit.
		
	self assert: ((dict collect: [ :each | each ] ) includes: 'string').
	self assert: ((dict collect: [ :each | each ] ) includes: 'string2')
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testCommitAndRead [

	| dict transaction materialized |
	
	"to remove"
	SoilTypeCodes initialize.
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict add: (#test -> 'string').
	transaction root: dict.
	transaction commit.

	transaction := soil newTransaction.
	materialized := transaction root.

	"should this not be transparently load it?"
	"if the Proxy inherits from ProtoObject, it works"
	self assert: (materialized at: #test) isSoilProxy
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testDetectIfNone [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	
	dict add: (#test -> 'string').
	dict add: (#test2 -> 'string').
	transaction commit.
		
	self assert: (dict detect: [:each | each = 'string'] ifNone: [ #error ]) equals: 'string'.
	self assert: (dict detect: [:each | each = 'tt'] ifNone: [ #error ]) equals: #error

]

{ #category : #tests }
SoilPersistentDictionaryTest >> testIncludesKey [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	
	dict add: (#test -> 'string').
	dict add: (#test2 -> 'string').
	transaction commit.
		
	self deny: (dict includesKey: #test1).
	self assert: (dict includesKey: #test2)
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testIsCollection [

	| dict |
	dict := SoilPersistentDictionary new.
	soil newTransaction makeRoot: dict.
	self assert: dict isCollection
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testIsEmpty [

	| dict |
	dict := SoilPersistentDictionary new.
	soil newTransaction makeRoot: dict.
	self assert: dict isEmpty
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testKeys [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	transaction commit.
		
	self assert: (dict keys includes: 'test').
	self assert: (dict keys includes: 'test2')
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testKeysAndValuesDo [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	transaction commit.
	dict keysAndValuesDo: [:key :value | 
		self assert:(key beginsWith: #test).
		self assert:(value beginsWith: 'string')]
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testNewPersistentDictionary [

	| dict |
	dict := SoilPersistentDictionary new.
	soil newTransaction makeRoot: dict.
	self assert: dict class identicalTo: SoilPersistentDictionary
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testRemoveKey [

	| dict transaction removed |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	removed := dict removeKey: #test.
	transaction commit.
	
	self assert: removed equals: 'string'.
	self assert: (dict at: #test2) equals: 'string2'.
	self deny: (dict includesKey: #test)
	
	


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testRemoveKeyIfAbsent [

	| dict transaction removed removed2|
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	removed := dict removeKey: #test ifAbsent: [ self error ].
	removed2 :=  dict removeKey: #tt ifAbsent: [ #absent ].
	transaction commit.
	
	self assert: removed equals: 'string'.
	self assert: (dict at: #test2) equals: 'string2'.
	self deny: (dict includesKey: #test).
	self assert: removed2 equals: #absent.
	


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testSize [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	
	dict add: (#test -> 'string').
	dict add: (#test2 -> 'string').
	transaction commit.
		
	self assert: (dict size) equals: 2
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testValues [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new.
	transaction makeRoot: dict.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	transaction commit.
		
	self assert: (dict values includes: 'string').
	self assert: (dict values includes: 'string2')
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testisEmpty [

	| dict |
	dict := SoilPersistentDictionary new.
	soil newTransaction makeRoot: dict.
	self assert: dict isEmpty
]
