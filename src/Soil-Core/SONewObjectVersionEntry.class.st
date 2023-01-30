Class {
	#name : #SONewObjectVersionEntry,
	#superclass : #SONewObjectEntry,
	#instVars : [
		'oldBytes'
	],
	#category : #'Soil-Core'
}

{ #category : #'accessing - defaults' }
SONewObjectVersionEntry class >> journalTypeCode [

	^ 2
]

{ #category : #accessing }
SONewObjectVersionEntry >> oldBytes: aCollection [
	oldBytes := aCollection
]

{ #category : #writing }
SONewObjectVersionEntry >> writeOn: aStream [
	super writeOn: aStream.
	aStream nextPutAll: oldBytes
]
