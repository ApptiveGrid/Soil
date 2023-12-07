Class {
	#name : #SoilNewObjectEntry,
	#superclass : #SoilTransactionJournalEntry,
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

{ #category : #committing }
SoilNewObjectEntry >> commitIn: soil [ 
	position := soil objectRepository  
		at: objectId 
		put: bytes.
	record ifNotNil: [ 
		record position: position.
		record := nil ]
]

{ #category : #accessing }
SoilNewObjectEntry >> container [
	^ 'segment #', objectId segment asString
]

{ #category : #accessing }
SoilNewObjectEntry >> context [
	^ objectId
]

{ #category : #committing }
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

{ #category : #accessing }
SoilNewObjectEntry >> objectIds [
	^ { objectId }
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
	bytesSize := aStream nextLengthEncodedInteger.
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
	aStream 
		nextPutLengthEncodedInteger: bytes size;
		nextPutAll: bytes
	
]
