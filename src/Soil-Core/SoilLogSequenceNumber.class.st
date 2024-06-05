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

{ #category : #comparing }
SoilLogSequenceNumber >> = aLogSequenceNumber [ 
	(aLogSequenceNumber class = self class) ifFalse: [ ^ false ].
	^ aLogSequenceNumber value = value
]

{ #category : #accessing }
SoilLogSequenceNumber >> fileNumber [
	"the high 40 bits are making up the file number"
	^ value bitShift: -24
]

{ #category : #accessing }
SoilLogSequenceNumber >> fileNumber: number offset: offset [ 
	(offset < 16777216) ifFalse: [ 
		Error signal: 'offset of LSN is to big. Must fit into 24 bits' ].
	value := number bitShift: 24.
	value := value bitOr: offset 
]

{ #category : #accessing }
SoilLogSequenceNumber >> fileOffset [ 
	^ value bitAnd: 16rFFFFFF
]

{ #category : #comparing }
SoilLogSequenceNumber >> hash [ 
	^ value hash
]

{ #category : #printing }
SoilLogSequenceNumber >> hexFileNumber [
	^ (self fileNumber printStringBase: 16 length: 6 padded: true) asLowercase 
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
		<< self hexFileNumber
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
