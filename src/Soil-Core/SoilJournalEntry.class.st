Class {
	#name : #SoilJournalEntry,
	#superclass : #Object,
	#instVars : [
		'transactionId'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'as yet unclassified' }
SoilJournalEntry class >> withTypeCode: anInteger [ 
	^ self allSubclasses 
		detect: [ :each | each journalTypeCode = anInteger ]
		ifNone: [ Error signal: 'cannot find class for journal type code ', anInteger asString ]
]

{ #category : #accessing }
SoilJournalEntry >> container [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilJournalEntry >> oldValue [
	^ nil
]

{ #category : #writing }
SoilJournalEntry >> readFrom: aStream [ 
	"skip because the type code is already read"
	transactionId := (aStream next: 8) asInteger
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
		nextPut: self class journalTypeCode;
		nextPutAll: (transactionId asByteArrayOfSize: 8)
]
