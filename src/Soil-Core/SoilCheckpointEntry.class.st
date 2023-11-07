Class {
	#name : #SoilCheckpointEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'checkpointedAt'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilCheckpointEntry class >> journalTypeCode [ 
	^ 11
]

{ #category : #accessing }
SoilCheckpointEntry >> address [
	^ ''
]

{ #category : #accessing }
SoilCheckpointEntry >> checkpointedAt [
	^ checkpointedAt
]

{ #category : #committing }
SoilCheckpointEntry >> commitIn: aTransaction [
	"make sure behavior registry gets flushed at the end of 
	a transaction"
	aTransaction behaviorRegistry flush.
	"as indexes are just created and keys/values being added,
	we need to flush sometime and the checkpoint time is good
	for this"
	aTransaction indexes do: #flush.
]

{ #category : #accessing }
SoilCheckpointEntry >> container [
	^ #soil
]

{ #category : #initialization }
SoilCheckpointEntry >> initialize [ 
	super initialize.
	checkpointedAt := DateAndTime now
]

{ #category : #accessing }
SoilCheckpointEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilCheckpointEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	checkpointedAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) asInteger / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilCheckpointEntry >> value [ 
	^ checkpointedAt 
]

{ #category : #writing }
SoilCheckpointEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := checkpointedAt asSeconds * 1000000 + (checkpointedAt nanoSecond // 1000).
	
	aStream nextPutLengthEncodedInteger:  timestamp
]
