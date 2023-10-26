Class {
	#name : #SoilLogSequenceNumber,
	#superclass : #Object,
	#instVars : [
		'value'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'as yet unclassified' }
SoilLogSequenceNumber class >> fileNumber: number offset: offset [ 
	^ self new 
		fileNumber: number offset: offset
]

{ #category : #accessing }
SoilLogSequenceNumber class >> value: anInteger [ 
	^ self new 
		value: anInteger 
]

{ #category : #accessing }
SoilLogSequenceNumber >> fileNumber [
	"the high 40 bits are making up the file number"
	^ value bitShift: -24
]

{ #category : #accessing }
SoilLogSequenceNumber >> fileNumber: number offset: offset [ 
	value := number bitShift: 24.
	value := value bitOr: offset 
]

{ #category : #'as yet unclassified' }
SoilLogSequenceNumber >> fileOffset [ 
	^ value bitAnd: 16rFFFFFF
]

{ #category : #accessing }
SoilLogSequenceNumber >> filename [
	^ (self fileNumber printStringBase: 16 length: 10 padded:  true) asLowercase 
]

{ #category : #'as yet unclassified' }
SoilLogSequenceNumber >> hexOffset [ 
	^ (self fileOffset printStringBase: 16 length: 6 padded: true) asLowercase 
]

{ #category : #testing }
SoilLogSequenceNumber >> isInitial [
	^ value = 0
]

{ #category : #printing }
SoilLogSequenceNumber >> printOn: aStream [ 
	aStream 
		<< 'LSN: ' 
		<< self filename
		<< '-'
		<< self hexOffset 
]

{ #category : #evaluating }
SoilLogSequenceNumber >> value [ 
	^ value
]

{ #category : #accessing }
SoilLogSequenceNumber >> value: anInteger [ 
	value := anInteger
]
