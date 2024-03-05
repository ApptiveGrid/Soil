Class {
	#name : #SoilCheckpointEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'checkpointedAt',
		'previousCheckpoint'
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
SoilCheckpointEntry >> commitIn: soil [
	"write all values in the heap to disk"
	soil writeEverythingToDisk 
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

{ #category : #accessing }
SoilCheckpointEntry >> previousCheckpoint [

	^ previousCheckpoint
]

{ #category : #accessing }
SoilCheckpointEntry >> previousCheckpoint: anObject [

	previousCheckpoint := anObject 
]

{ #category : #printing }
SoilCheckpointEntry >> printOn: aStream [ 
	aStream 
		<< 'checkpointed at: ' 
		<< checkpointedAt printString 
		<< ', previous: '
		<< previousCheckpoint printString
]

{ #category : #'instance creation' }
SoilCheckpointEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	checkpointedAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) asInteger / 1000) milliSeconds) asLocal.
	previousCheckpoint := SoilLogSequenceNumber readFrom: aStream
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
	
	aStream nextPutLengthEncodedInteger:  timestamp.
	previousCheckpoint writeOn: aStream 
]
