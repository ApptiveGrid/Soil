Class {
	#name : #SoilIndexJournalEntry,
	#superclass : #SoilTransactionJournalEntry,
	#instVars : [
		'segment',
		'id'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #testing }
SoilIndexJournalEntry class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexJournalEntry
]

{ #category : #'accessing - defaults' }
SoilIndexJournalEntry class >> journalTypeCode [
	^ 0
]

{ #category : #accessing }
SoilIndexJournalEntry >> container [
	^ 'index: ', id asString
]

{ #category : #accessing }
SoilIndexJournalEntry >> id [

	^ id
]

{ #category : #accessing }
SoilIndexJournalEntry >> id: aString [ 
	id := aString
]

{ #category : #'instance creation' }
SoilIndexJournalEntry >> readFrom: aStream [ 
	| idSize |
	super readFrom: aStream.
	segment := aStream nextLengthEncodedInteger.
	idSize := aStream next.
	id := (aStream next: idSize) asString
]

{ #category : #accessing }
SoilIndexJournalEntry >> segment [

	^ segment
]

{ #category : #accessing }
SoilIndexJournalEntry >> segment: anInteger [ 
	segment := anInteger
]

{ #category : #writing }
SoilIndexJournalEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream 
		nextPutLengthEncodedInteger: segment;
		nextPut: id size; 
		nextPutAll: id asByteArray
	
]
