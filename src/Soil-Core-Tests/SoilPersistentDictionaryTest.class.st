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

{ #category : #running }
SoilPersistentDictionaryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
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
