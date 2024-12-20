Class {
	#name : #SoilBasicSerializer,
	#superclass : #SoilObjectCodec,
	#category : #'Soil-Serializer-Serializer/Materializer'
}

{ #category : #'instance creation' }
SoilBasicSerializer class >> on: aStream [ 
	^ self new 
		stream: aStream 
]

{ #category : #public }
SoilBasicSerializer class >> serializeToBytes: anObject [ 

	^ (self on: ByteArray new writeStream) 
		serialize: anObject

]

{ #category : #'writing - basic' }
SoilBasicSerializer >> basicNextPutString: aString [ 
	self
		nextPutLengthEncodedInteger: aString size;
		nextPutBytesFrom: aString
]

{ #category : #writing }
SoilBasicSerializer >> basicNextPutSymbol: aSymbol [ 
	self
		nextPutLengthEncodedInteger: aSymbol size;
		nextPutBytesFrom: aSymbol
]

{ #category : #'writing - basic' }
SoilBasicSerializer >> nextPutByte: anInteger [ 
	stream nextPut: anInteger
]

{ #category : #writing }
SoilBasicSerializer >> nextPutByteArray: aByteArray [
	self 
		nextPutByte: TypeCodeByteArray; 
		nextPutLengthEncodedInteger: aByteArray size;
		nextPutBytesFrom: aByteArray
]

{ #category : #'writing - basic' }
SoilBasicSerializer >> nextPutBytesFrom: aByteArray [
	stream nextBytesPutAll: aByteArray 

]

{ #category : #writing }
SoilBasicSerializer >> nextPutCharacter: aCharacter [
	self nextPutByte: TypeCodeCharacter.
	self nextPutLengthEncodedInteger: aCharacter asInteger
]

{ #category : #writing }
SoilBasicSerializer >> nextPutDate: aDate [ 
	self 
		nextPutByte: TypeCodeDate; 
		nextPutInteger: aDate julianDayNumber - 2415386; 
		nextPutInteger: ((aDate offset hours * 60) + aDate offset minutes)
]

{ #category : #writing }
SoilBasicSerializer >> nextPutDateAndTime: aDateAndTime [ 
	self 
		nextPutByte: TypeCodeDateAndTime; 
		nextPutInteger: aDateAndTime julianDayNumberUTC - 2415386; 
		nextPutLengthEncodedInteger: aDateAndTime secondsSinceMidnightUTC;
		nextPutLengthEncodedInteger: aDateAndTime nanoSecond;
		nextPutInteger: ((aDateAndTime offset hours * 60) + aDateAndTime offset minutes)
]

{ #category : #writing }
SoilBasicSerializer >> nextPutFalse: aBoolean [ 
	self nextPutByte: TypeCodeFalse 
]

{ #category : #writing }
SoilBasicSerializer >> nextPutFloat: aFloat [ 
	self
		nextPutByte: TypeCodeFloat;
		nextPutLengthEncodedInteger: (aFloat at: 1);
		nextPutLengthEncodedInteger: (aFloat at: 2)
]

{ #category : #writing }
SoilBasicSerializer >> nextPutFraction: aNumber [
	"we know that numerator and denominator are SmallIntegers"
	self
		nextPutByte: TypeCodeFraction;
		nextPutLengthEncodedInteger: aNumber numerator;
		nextPutLengthEncodedInteger: aNumber denominator
]

{ #category : #writing }
SoilBasicSerializer >> nextPutInteger: anInteger [ 
	(anInteger < 0)
		ifTrue: [ self nextPutLargeNegativeInteger: anInteger ] 
		ifFalse: [ self nextPutLargePositiveInteger: anInteger ]
]

{ #category : #writing }
SoilBasicSerializer >> nextPutLargeNegativeInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeNegativeInteger;
		nextPutLengthEncodedInteger: 0 - anInteger
]

{ #category : #writing }
SoilBasicSerializer >> nextPutLargePositiveInteger: anInteger [ 
	self 
		nextPutByte: TypeCodePositiveInteger;
		nextPutLengthEncodedInteger: anInteger
]

{ #category : #'writing - basic' }
SoilBasicSerializer >> nextPutLengthEncodedInteger: anInteger [ 
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	stream nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilBasicSerializer >> nextPutNil: anUndefinedObject [ 
	self nextPutByte: TypeCodeUndefined 
]

{ #category : #writing }
SoilBasicSerializer >> nextPutScaledDecimal: aNumber [
	"we know that numerator, denominator and scale are SmallIntegers"
	self
		nextPutByte: TypeCodeScaledDecimal;
		nextPutInteger: aNumber numerator;
		nextPutLengthEncodedInteger: aNumber denominator;
		nextPutLengthEncodedInteger: aNumber scale 
]

{ #category : #writing }
SoilBasicSerializer >> nextPutString: aString [ 
	self
		nextPutByte: TypeCodeString;
		basicNextPutString: aString
]

{ #category : #writing }
SoilBasicSerializer >> nextPutSymbol: aSymbol [ 
	self
		nextPutByte: TypeCodeSymbol;
		basicNextPutSymbol: aSymbol
]

{ #category : #writing }
SoilBasicSerializer >> nextPutTime: aTime [ 
	self
		nextPutByte: TypeCodeTime;
		nextPutLengthEncodedInteger: aTime asSeconds;
		nextPutLengthEncodedInteger: aTime nanoSecond 
]

{ #category : #writing }
SoilBasicSerializer >> nextPutTrue: aBoolean [ 
	self nextPutByte: TypeCodeTrue 
]

{ #category : #writing }
SoilBasicSerializer >> nextPutWideString: aWideString [ 
	| buf |
	buf := self class encodeString: aWideString.
	self
		nextPutByte: TypeCodeWideString;
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf
]

{ #category : #writing }
SoilBasicSerializer >> nextPutWideSymbol: aSymbol [
	| buf |
	buf := self class encodeString: aSymbol.
	self
		nextPutByte: TypeCodeWideSymbol;
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf
]

{ #category : #private }
SoilBasicSerializer >> serialize: anObject [
	anObject soilBasicSerialize: self.
	stream flush.
	^ stream contents
]
