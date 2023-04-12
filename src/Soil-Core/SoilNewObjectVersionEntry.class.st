Class {
	#name : #SoilNewObjectVersionEntry,
	#superclass : #SoilNewObjectEntry,
	#instVars : [
		'oldBytes'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewObjectVersionEntry class >> journalTypeCode [

	^ 2
]

{ #category : #accessing }
SoilNewObjectVersionEntry >> oldBytes: aCollection [ 
	oldBytes := aCollection
]

{ #category : #writing }
SoilNewObjectVersionEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutAll: oldBytes.
	
]
