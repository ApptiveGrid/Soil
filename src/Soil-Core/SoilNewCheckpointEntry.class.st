Class {
	#name : #SoilNewCheckpointEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'checkpointedAt'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewCheckpointEntry class >> journalTypeCode [ 
	^ 9
]

{ #category : #accessing }
SoilNewCheckpointEntry >> address [
	^ ''
]

{ #category : #accessing }
SoilNewCheckpointEntry >> checkpointedAt [
	^ checkpointedAt
]

{ #category : #committing }
SoilNewCheckpointEntry >> commitIn: aTransaction [
	"make sure behavior registry gets flushed at the end of 
	a transaction"
	aTransaction behaviorRegistry flush.
	"as indexes are just created and keys/values being added,
	we need to flush sometime and the checkpoint time is good
	for this"
	aTransaction indexes do: #flush.
]

{ #category : #accessing }
SoilNewCheckpointEntry >> container [
	^ #soil
]

{ #category : #initialization }
SoilNewCheckpointEntry >> initialize [ 
	super initialize.
	checkpointedAt := DateAndTime now
]

{ #category : #accessing }
SoilNewCheckpointEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilNewCheckpointEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	checkpointedAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) asInteger / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilNewCheckpointEntry >> value [ 
	^ checkpointedAt 
]

{ #category : #writing }
SoilNewCheckpointEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := checkpointedAt asSeconds * 1000000 + (checkpointedAt nanoSecond // 1000).
	
	aStream nextPutLengthEncodedInteger:  timestamp
]
