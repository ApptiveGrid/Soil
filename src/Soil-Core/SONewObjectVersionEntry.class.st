Class {
	#name : #SONewObjectVersionEntry,
	#superclass : #SONewObjectEntry,
	#instVars : [
		'oldBytes'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SONewObjectVersionEntry class >> journalTypeCode [
	^ 1
]

{ #category : #accessing }
SONewObjectVersionEntry >> oldBytes: aCollection [ 
	oldBytes := aCollection
]

{ #category : #writing }
SONewObjectVersionEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutAll: oldBytes.
	
]
