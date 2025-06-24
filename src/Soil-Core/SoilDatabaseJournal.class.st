Class {
	#name : #SoilDatabaseJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactionJournals'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #visting }
SoilDatabaseJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitDatabaseJournal: self
]

{ #category : #adding }
SoilDatabaseJournal >> addTransactionJournal: aTransactionJournal [ 
	aTransactionJournal index ifNil: [ self halt ].
	transactionJournals 
		at: aTransactionJournal index
		put: aTransactionJournal

]

{ #category : #copying }
SoilDatabaseJournal >> copyFrom: start to: end [ 
| journals |
	journals := OrderedCollection new.
	self transactionJournalsStartingAt: start do: [ :j |
		(j index <= end) ifTrue: [ journals add: j ] ]. 
	^ SoilMemoryDatabaseJournal new 
		soil: soil;
		transactionJournals: journals
]

{ #category : #enumerating }
SoilDatabaseJournal >> do: aBlock [ 
	transactionJournals do: aBlock
]

{ #category : #accessing }
SoilDatabaseJournal >> lastIndex [
	^ self lastTransactionJournal 
		ifNotNil: [ :journal | journal index ]
		ifNil: [ 0 ]
]

{ #category : #accessing }
SoilDatabaseJournal >> lastTransactionJournal [
	| maxKey |
	maxKey := 0.
	transactionJournals keysAndValuesDo: [ :key :value |
		(key > maxKey) ifTrue: [ maxKey := key ] ].
	^ transactionJournals at: maxKey		
]

{ #category : #accessing }
SoilDatabaseJournal >> soil [
	^ soil
]

{ #category : #accessing }
SoilDatabaseJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournalAt: anInteger [ 
	^ transactionJournals at: anInteger
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournals: anObject [

	transactionJournals := anObject
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournalsStartingAt: index do: aBlock [ 
	^ self subclassResponsibility
]

{ #category : #adding }
SoilDatabaseJournal >> verifyNextJournalIndex: index [ 
	"transaction journals have a strict sequence in the same way the
	databaseVersion has. So we check that this assumption is kept"
	transactionJournals isEmpty 
		ifTrue: [ ^ self ]
		ifFalse: [ 
			((self lastTransactionJournal index + 1) = index)
				ifFalse: [ 
					Transcript show: ('journal index is not valid: current last index is ', self lastTransactionJournal index printString, ', no index to be added is ', index printString); cr ] ]
		
]
