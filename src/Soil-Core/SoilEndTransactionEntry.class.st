Class {
	#name : #SoilEndTransactionEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'checkpointedAt'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilEndTransactionEntry class >> journalTypeCode [ 
	^ 9
]

{ #category : #accessing }
SoilEndTransactionEntry >> address [
	^ ''
]

{ #category : #accessing }
SoilEndTransactionEntry >> checkpointedAt [
	^ checkpointedAt
]

{ #category : #committing }
SoilEndTransactionEntry >> commitIn: aTransaction [
	"make sure behavior registry gets flushed at the end of 
	a transaction"
	aTransaction behaviorRegistry flush.
	"as indexes are just created and keys/values being added,
	we need to flush sometime and the checkpoint time is good
	for this"
	aTransaction indexes do: #flush.
]

{ #category : #accessing }
SoilEndTransactionEntry >> container [
	^ #soil
]

{ #category : #initialization }
SoilEndTransactionEntry >> initialize [ 
	super initialize.
	checkpointedAt := DateAndTime now
]

{ #category : #testing }
SoilEndTransactionEntry >> isEndEntry [
	^ true
]

{ #category : #accessing }
SoilEndTransactionEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilEndTransactionEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	checkpointedAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) asInteger / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilEndTransactionEntry >> value [ 
	^ checkpointedAt 
]

{ #category : #writing }
SoilEndTransactionEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := checkpointedAt asSeconds * 1000000 + (checkpointedAt nanoSecond // 1000).
	
	aStream nextPutLengthEncodedInteger:  timestamp
]
