Class {
	#name : #SoilSerializer,
	#superclass : #SoilObjectCodec,
	#instVars : [
		'path',
		'objectRepository',
		'rootObject',
		'objects',
		'classes',
		'stream'
	],
	#category : #'Soil-Core'
}

{ #category : #public }
SoilSerializer class >> serializeToBytes: anObject [ 
	| stream |
	stream := ByteArray new writeStream.
	self new 
		rawStream: stream;
		serialize: anObject.
	^ stream flush; contents
]

{ #category : #public }
SoilSerializer >> classDescriptionFor: aClass [ 
	classes ifNil: [ classes := Dictionary new  ].
	^ classes 
		at: aClass 
		ifAbsentPut: [ SOClassDescription for: aClass ]
]

{ #category : #writing }
SoilSerializer >> nextPutArray: anArray [ 
	stream nextPutByte: ArrayCode.
	self nextPutLengthEncodedInteger: anArray size.
	1 to: anArray size do: [:i | 
		(anArray at: i) soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutByte: anInteger [ 
	stream nextPutByte: anInteger
]

{ #category : #writing }
SoilSerializer >> nextPutInteger: anInteger [ 
	(anInteger < 0)
		ifTrue: [ self nextPutLargeNegativeInteger: anInteger ] 
		ifFalse: [ self nextPutLargePositiveInteger: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutLargeNegativeInteger: anInteger [ 
	stream nextPutByte: LargeNegativeIntegerCode.
	self nextPutLengthEncodedInteger: anInteger
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutLargePositiveInteger: anInteger [ 
	stream nextPutByte: LargePositiveIntegerCode.
	self nextPutLengthEncodedInteger: anInteger
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutLengthEncodedInteger: anInteger [ 
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	anInteger < 128 ifTrue: [ ^ self putByte: anInteger ].
	self
		putByte: ((anInteger bitAnd: 127) bitOr: 128);
		putPositiveInteger: (anInteger bitShift: -7)
]

{ #category : #writing }
SoilSerializer >> nextPutNil: anUndefinedObject [ 
	stream nextPutByte: UndefinedCode 
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutObjectType [
	stream nextPutByte: NewObjectCode 
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutPositiveInteger: anInteger [ 
	stream nextPutByte: LargePositiveIntegerCode.
	self nextPutLengthEncodedInteger: anInteger
]

{ #category : #public }
SoilSerializer >> putByte: anInteger [ 
	stream nextPutByte: anInteger 
]

{ #category : #accessing }
SoilSerializer >> rawStream: aWriteStream [ 
	stream := SoilMemoryStream on: aWriteStream 
]

{ #category : #registry }
SoilSerializer >> register: anObject [
	objects ifNil: [ objects := Set new ].
	(objects includes: anObject) ifTrue: [ self halt ].
	objects add: anObject  
]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	rootObject := anObject.
	rootObject soilSerialize: self.
	stream flush.
	^ stream contents
]
