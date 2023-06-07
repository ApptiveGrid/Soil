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
	super readFrom: aStream.
	createdAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilNewTransactionEntry >> value [ 
	^ createdAt 
]

{ #category : #writing }
SoilNewTransactionEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := createdAt asSeconds * 1000000 + (createdAt nanoSecond // 1000).
	aStream nextPutLengthEncodedInteger: timestamp
]
