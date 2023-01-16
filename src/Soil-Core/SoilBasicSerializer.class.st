Class {
	#name : #SoilBasicSerializer,
	#superclass : #SoilObjectCodec,
	#category : #'Soil-Core-Serialization'
}

{ #category : #'writing - basic' }
SoilBasicSerializer >> basicNextPutString: aString [ 
	| buf |
	buf := aString asByteArray.
	self
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf
]

{ #category : #writing }
SoilBasicSerializer >> basicNextPutSymbol: aSymbol [ 
	self
		nextPutLengthEncodedInteger: aSymbol size;
		nextPutBytesFrom: aSymbol asByteArray
]

{ #category : #'writing - basic' }
SoilBasicSerializer >> nextPutByte: anInteger [ 
	stream nextPut: anInteger
]

{ #category : #writing }
SoilBasicSerializer >> nextPutByteArray: aByteArray [
	self 
		nextPutByte: TypeCodeByteArray; 
		nextPutLengthEncodedInteger: aByteArray size.
	1 to: aByteArray size do: [:i |
		self nextPutByte: (aByteArray at: i)].
]

{ #category : #'writing - basic' }
SoilBasicSerializer >> nextPutBytesFrom: aByteArray [
	stream nextPutAll: aByteArray 

]

{ #category : #writing }
SoilBasicSerializer >> nextPutCharacter: aCharacter [
	"we store 8bit characters with TypeCodeByteCharacter to save some space"
	| charAsInteger |
	charAsInteger := aCharacter asInteger.
	self nextPutByte: (charAsInteger > 255
			 ifTrue: [ TypeCodeCharacter ]
			 ifFalse: [ TypeCodeByteCharacter ]).
	self nextPutLengthEncodedInteger: charAsInteger
]

{ #category : #writing }
SoilBasicSerializer >> nextPutDate: aDate [ 
	self 
		nextPutByte: TypeCodeDate; 
		nextPutLengthEncodedInteger: aDate julianDayNumber - 2415386; 
		nextPutInteger: ((aDate offset hours * 60) + aDate offset minutes)
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
		nextPutByte: TypeCodeLargeNegativeInteger;
		nextPutLengthEncodedInteger: 0 - anInteger
]

{ #category : #writing }
SoilBasicSerializer >> nextPutLargePositiveInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeLargePositiveInteger;
		nextPutLengthEncodedInteger: anInteger
]

{ #category : #'writing - basic' }
SoilBasicSerializer >> nextPutLengthEncodedInteger: anInteger [ 
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	anInteger < 128 ifTrue: [ ^ self nextPutByte: anInteger ].
	self
		nextPutByte: ((anInteger bitAnd: 127) bitOr: 128);
		nextPutLengthEncodedInteger: (anInteger bitShift: -7)
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
		nextPutLengthEncodedInteger: aNumber numerator;
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
		nextPutLengthEncodedInteger: aTime asSeconds
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
	buf := aSymbol asString utf8Encoded.
	self
		nextPutByte: TypeCodeWideSymbol;
		nextPutLengthEncodedInteger:  buf size;
		nextPutBytesFrom: buf
]
