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

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> importEntry: aSoilTransactionJournal [ 
	self addTransactionJournal: aSoilTransactionJournal
]

{ #category : #'as yet unclassified' }
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
SoilDatabaseJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournalAt: anInteger [ 
	^ transactionJournals 
		at: anInteger 
		ifAbsentPut: [ self halt ]
]

{ #category : #accessing }
SoilDatabaseJournal >> transactionJournals: anObject [

	transactionJournals := anObject
]
