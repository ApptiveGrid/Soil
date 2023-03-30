Class {
	#name : #SONewObjectEntry,
	#superclass : #SOJournalEntry,
	#instVars : [
		'objectId',
		'bytes',
		'position',
		'record'
	],
	#category : #'Soil-Core'
}

{ #category : #'accessing - defaults' }
SONewObjectEntry class >> journalTypeCode [

	^ 1
]

{ #category : #accessing }
SONewObjectEntry >> bytes: aCollection [ 
	bytes := aCollection
]

{ #category : #'as yet unclassified' }
SONewObjectEntry >> commitIn: transaction [ 
	position := transaction objectRepository  
		at: objectId 
		put: bytes.
	record ifNotNil: [ 
		record position: position ]
]

{ #category : #accessing }
SONewObjectEntry >> objectId: aSOObjectId [ 
	objectId := aSOObjectId
]

{ #category : #accessing }
SONewObjectEntry >> record [

	^ record
]

{ #category : #accessing }
SONewObjectEntry >> record: anObject [

	record := anObject
]

{ #category : #writing }
SONewObjectEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	objectId writeOn: aStream.
	aStream 
		nextPutAll: bytes
	
]
