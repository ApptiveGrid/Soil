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
SoilNewObjectEntry >> address [
	^ objectId 
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
SoilNewObjectEntry >> container [
	^ 'segment #', objectId segment asString
]

{ #category : #accessing }
SoilNewObjectEntry >> context [
	^ objectId
]

{ #category : #'as yet unclassified' }
SoilNewObjectEntry >> effect [ 
	^ 'position: ', position asString
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

{ #category : #'instance creation' }
SoilNewObjectEntry >> readFrom: aStream [ 
	| bytesSize |
	super readFrom: aStream.
	objectId := SoilObjectId readFrom: aStream.
	bytesSize := (aStream next: 2) asInteger.
	bytes := aStream next: bytesSize.
]

{ #category : #accessing }
SoilNewObjectEntry >> record [

	^ record
]

{ #category : #accessing }
SoilNewObjectEntry >> record: anObject [

	record := anObject
]

{ #category : #accessing }
SoilNewObjectEntry >> value [ 
	^ position 
]

{ #category : #writing }
SoilNewObjectEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	objectId writeOn: aStream.
	aStream nextPutAll: (bytes size asByteArrayOfSize: 2).
	aStream 
		nextPutAll: bytes
	
]
