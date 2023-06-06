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
	| size |
	super readFrom: aStream.
	size := aStream next.
	checkpointedAt := DateAndTime epoch + ((aStream next: size) asInteger / 1000) milliSeconds  
]

{ #category : #accessing }
SoilNewCheckpointEntry >> value [ 
	^ checkpointedAt 
]

{ #category : #writing }
SoilNewCheckpointEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := (checkpointedAt asSeconds * 1000000 + (checkpointedAt nanoSecond // 1000)) asByteArray.
	
	aStream
		nextPut: timestamp size; 
		nextPutAll: timestamp
]
