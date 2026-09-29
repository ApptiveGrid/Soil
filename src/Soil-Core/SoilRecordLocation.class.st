"
Where a record lies in an object file and how many bytes it takes there, head and payload. It is what the space a record occupies is computed from - which blocks of the file it overlaps - without reading what it holds.
"
Class {
	#name : #SoilRecordLocation,
	#superclass : #Object,
	#instVars : [
		'position',
		'length'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilRecordLocation class >> position: anInteger length: aLength [
	^ self new 
		position: anInteger length: aLength;
		yourself
]

{ #category : #comparing }
SoilRecordLocation >> = anObject [
	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ position = anObject position and: [ length = anObject length ]
]

{ #category : #accessing }
SoilRecordLocation >> end [
	"the first position behind the record"
	^ position + length
]

{ #category : #comparing }
SoilRecordLocation >> hash [
	^ position hash bitXor: length hash
]

{ #category : #accessing }
SoilRecordLocation >> length [
	^ length
]

{ #category : #accessing }
SoilRecordLocation >> position [
	^ position
]

{ #category : #initialization }
SoilRecordLocation >> position: anInteger length: aLength [
	position := anInteger.
	length := aLength
]

{ #category : #printing }
SoilRecordLocation >> printOn: aStream [
	aStream << 'record at ' << position printString << ', ' << length printString << ' bytes'
]
