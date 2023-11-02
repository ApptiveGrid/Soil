Class {
	#name : #SoilJournalEntry,
	#superclass : #Object,
	#instVars : [
		'transactionId'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #testing }
SoilJournalEntry class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilJournalEntry
]

{ #category : #'instance creation' }
SoilJournalEntry class >> readFrom: aStream [ 
	| transactionId |
	transactionId := self readTransactionIdFrom: aStream.
	^ (self withTypeCode: aStream next asInteger) new 
		transactionId: transactionId;
		readFrom: aStream;
		yourself
]

{ #category : #'instance creation' }
SoilJournalEntry class >> readTransactionIdFrom: aStream [ 
	^ (aStream next: 8) asInteger
]

{ #category : #'instance creation' }
SoilJournalEntry class >> withTypeCode: anInteger [ 
	^ self allSubclasses 
		detect: [ :each | each journalTypeCode = anInteger ]
		ifNone: [ Error signal: 'cannot find class for journal type code ', anInteger asString ]
]

{ #category : #accessing }
SoilJournalEntry >> container [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilJournalEntry >> isEnd [
	^ false
]

{ #category : #accessing }
SoilJournalEntry >> oldValue [
	^ nil
]

{ #category : #writing }
SoilJournalEntry >> readFrom: aStream [ 
	"skip because the transaction id and type code are already read"
]

{ #category : #accessing }
SoilJournalEntry >> transactionId [

	^ transactionId
]

{ #category : #accessing }
SoilJournalEntry >> transactionId: anObject [

	transactionId := anObject
]

{ #category : #validating }
SoilJournalEntry >> validateIn: aSoilTransaction [ 
	
]

{ #category : #writing }
SoilJournalEntry >> writeOn: aStream [ 
	aStream 
		nextPutAll: (transactionId asByteArrayOfSize: 8);
		nextPut: self class journalTypeCode
]
