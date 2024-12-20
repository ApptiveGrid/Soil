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
SoilNewObjectVersionEntry >> oldBytes [
	^ oldBytes
]

{ #category : #accessing }
SoilNewObjectVersionEntry >> oldBytes: aCollection [ 
	oldBytes := aCollection
]

{ #category : #'instance creation' }
SoilNewObjectVersionEntry >> readFrom: aStream [ 
	| oldBytesSize |
	super readFrom: aStream.
	oldBytesSize := aStream nextLengthEncodedInteger.
	oldBytes := aStream next: oldBytesSize
]

{ #category : #writing }
SoilNewObjectVersionEntry >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream nextPutLengthEncodedInteger: oldBytes size.
	aStream nextPutAll: oldBytes.
	
]
