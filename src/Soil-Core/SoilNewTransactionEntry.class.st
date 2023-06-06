Class {
	#name : #SoilNewTransactionEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'createdAt'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewTransactionEntry class >> journalTypeCode [ 
	^ 8
]

{ #category : #accessing }
SoilNewTransactionEntry >> address [
	^ ''
]

{ #category : #committing }
SoilNewTransactionEntry >> commitIn: aTransaction [ 
]

{ #category : #accessing }
SoilNewTransactionEntry >> container [
	^ #soil
]

{ #category : #accessing }
SoilNewTransactionEntry >> createdAt: aDateAndTime [ 
	createdAt := aDateAndTime 
]

{ #category : #accessing }
SoilNewTransactionEntry >> objectId [
	^ nil
]

{ #category : #'instance creation' }
SoilNewTransactionEntry >> readFrom: aStream [ 
	| size |
	super readFrom: aStream.
	size := aStream next.
	createdAt := DateAndTime epoch + ((aStream next: size) asInteger / 1000) milliseconds  
]

{ #category : #accessing }
SoilNewTransactionEntry >> value [ 
	^ createdAt 
]

{ #category : #writing }
SoilNewTransactionEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	timestamp := createdAt asMicrosecondsSinceEpoch asByteArray.
	aStream
		nextPut: timestamp size; 
		nextPutAll: timestamp
]
