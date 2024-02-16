Class {
	#name : #SoilLogSequenceNumber,
	#superclass : #Object,
	#instVars : [
		'value'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'instance creation' }
SoilLogSequenceNumber class >> fileNumber: number offset: offset [ 
	^ self new 
		fileNumber: number offset: offset
]

{ #category : #'instance creation' }
SoilLogSequenceNumber class >> readFrom: aStream [

	^ self value: aStream nextLengthEncodedInteger
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

{ #category : #accessing }
SoilLogSequenceNumber >> fileOffset [ 
	^ value bitAnd: 16rFFFFFF
]

{ #category : #accessing }
SoilLogSequenceNumber >> hexOffset [ 
	^ (self fileOffset printStringBase: 16 length: 6 padded: true) asLowercase 
]

{ #category : #testing }
SoilLogSequenceNumber >> isInitial [
	^ value = 0
]

{ #category : #accessing }
SoilLogSequenceNumber >> nextFilename [
	^ self filename: self fileNumber + 1
]

{ #category : #printing }
SoilLogSequenceNumber >> printOn: aStream [ 
	aStream 
		<< 'LSN: ' 
		<< self fileNumber asString
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

{ #category : #writing }
SoilLogSequenceNumber >> writeOn: aStream [ 
	aStream nextPutLengthEncodedInteger: value
]
