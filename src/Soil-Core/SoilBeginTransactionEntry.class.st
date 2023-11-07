Class {
	#name : #SoilBeginTransactionEntry,
	#superclass : #SoilTransactionJournalEntry,
	#instVars : [
		'createdAt',
		'readVersion'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilBeginTransactionEntry class >> journalTypeCode [ 
	^ 8
]

{ #category : #accessing }
SoilBeginTransactionEntry >> address [
	^ ''
]

{ #category : #committing }
SoilBeginTransactionEntry >> commitIn: aTransaction [ 
]

{ #category : #accessing }
SoilBeginTransactionEntry >> container [
	^ #soil
]

{ #category : #accessing }
SoilBeginTransactionEntry >> createdAt [
	^ createdAt
]

{ #category : #accessing }
SoilBeginTransactionEntry >> createdAt: aDateAndTime [ 
	createdAt := aDateAndTime 
]

{ #category : #accessing }
SoilBeginTransactionEntry >> objectId [
	^ nil
]

{ #category : #accessing }
SoilBeginTransactionEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilBeginTransactionEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	createdAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilBeginTransactionEntry >> readVersion [

	^ readVersion
]

{ #category : #accessing }
SoilBeginTransactionEntry >> readVersion: anObject [

	readVersion := anObject
]

{ #category : #accessing }
SoilBeginTransactionEntry >> value [ 
	^ createdAt 
]

{ #category : #writing }
SoilBeginTransactionEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := createdAt asSeconds * 1000000 + (createdAt nanoSecond // 1000).
	aStream nextPutLengthEncodedInteger: timestamp
]
