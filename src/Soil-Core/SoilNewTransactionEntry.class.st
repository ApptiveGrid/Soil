Class {
	#name : #SoilNewTransactionEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'createdAt',
		'readVersion'
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
SoilNewTransactionEntry >> createdAt [
	^ createdAt
]

{ #category : #accessing }
SoilNewTransactionEntry >> createdAt: aDateAndTime [ 
	createdAt := aDateAndTime 
]

{ #category : #accessing }
SoilNewTransactionEntry >> objectId [
	^ nil
]

{ #category : #accessing }
SoilNewTransactionEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilNewTransactionEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	createdAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilNewTransactionEntry >> readVersion [

	^ readVersion
]

{ #category : #accessing }
SoilNewTransactionEntry >> readVersion: anObject [

	readVersion := anObject
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
