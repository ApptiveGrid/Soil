Class {
	#name : #SONewObjectEntry,
	#superclass : #SOJournalEntry,
	#instVars : [
		'objectId',
		'bytes'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SONewObjectEntry class >> journalTypeCode [
	^ 1
]

{ #category : #accessing }
SONewObjectEntry >> bytes: aCollection [ 
	bytes := aCollection
]

{ #category : #accessing }
SONewObjectEntry >> commit [
	self objectRepository  
		at: objectId 
		put: bytes
]

{ #category : #'as yet unclassified' }
SONewObjectEntry >> commitIn: transaction [ 
	transaction objectRepository  
		at: objectId 
		put: bytes
]

{ #category : #accessing }
SONewObjectEntry >> objectId: aSOObjectId [ 
	objectId := aSOObjectId
]

{ #category : #writing }
SONewObjectEntry >> writeOn: aStream [ 
	aStream nextPut: self class journalTypeCode.
	objectId writeOn: aStream.
	aStream 
		nextPutAll: bytes
	
]
