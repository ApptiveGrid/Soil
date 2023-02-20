Class {
	#name : #SoilPersistentDictionaryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
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

{ #category : #tests }
SoilPersistentDictionaryTest >> testAt [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new soilMakePersistentIn: transaction.
	dict add: (#test -> 'string').
	transaction commit.
		
	self assert: (dict at: #test) equals: 'string'.
	


]

{ #category : #tests }
SoilPersistentDictionaryTest >> testAtPut [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new soilMakePersistentIn: transaction.
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
	dict := SoilPersistentDictionary new soilMakePersistentIn: transaction.
	dict add: (#test -> 'string').
	transaction root: dict.
	transaction commit.

	transaction := soil newTransaction.
	materialized := transaction root.

	"should this not be transparently load it?"
	"if the Proxy inherits from ProtoObject, it works"
	self assert: (materialized at: #test) class equals: SOObjectProxy
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testNewPersistentDictionary [

	| dict |
	dict := SoilPersistentDictionary new soilMakePersistentIn:
		        soil newTransaction.
	self assert: dict class identicalTo: SoilPersistentDictionary
]

{ #category : #tests }
SoilPersistentDictionaryTest >> testRemoveKey [

	| dict transaction |
	transaction := soil newTransaction.
	dict := SoilPersistentDictionary new soilMakePersistentIn: transaction.
	dict at: #test put: 'string'.
	dict at: #test2 put: 'string2'.
	dict removeKey: #test.
	transaction commit.
		
	self assert: (dict at: #test2) equals: 'string2'.
	self deny: (dict includesKey: #test)
	
	


]
