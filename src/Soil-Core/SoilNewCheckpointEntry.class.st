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
