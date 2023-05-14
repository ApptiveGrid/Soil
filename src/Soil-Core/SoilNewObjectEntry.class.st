Class {
	#name : #SoilNewObjectEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'objectId',
		'bytes',
		'position',
		'record'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewObjectEntry class >> journalTypeCode [

	^ 1
]

{ #category : #accessing }
SoilNewObjectEntry >> bytes: aCollection [ 
	bytes := aCollection
]

{ #category : #'as yet unclassified' }
SoilNewObjectEntry >> commitIn: transaction [ 
	position := transaction objectRepository  
		at: objectId 
		put: bytes.
	record ifNotNil: [ 
		record position: position ]
]

{ #category : #accessing }
SoilNewObjectEntry >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilNewObjectEntry >> objectId: aSOObjectId [ 
	objectId := aSOObjectId
]

{ #category : #printing }
SoilNewObjectEntry >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' objectId: '
		<< objectId asString 
]

{ #category : #accessing }
SoilNewObjectEntry >> record [

	^ record
]

{ #category : #accessing }
SoilNewObjectEntry >> record: anObject [

	record := anObject
]

{ #category : #writing }
SoilNewObjectEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	objectId writeOn: aStream.
	aStream 
		nextPutAll: bytes
	
]
