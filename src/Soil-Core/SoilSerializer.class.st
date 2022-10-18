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

{ #category : #writing }
SoilSerializer >> basicNextPutString: aString [ 
	| buf |
	buf := aString asByteArray.
	self
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf len: buf size
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
	self nextPutByte: TypeCodeArray.
	self nextPutLengthEncodedInteger: anArray size.
	1 to: anArray size do: [:i | 
		(anArray at: i) soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutAssociation: anAssociation [ 
	self nextPutByte: TypeCodeAssociation.
	anAssociation key soilSerialize: self.
	anAssociation value soilSerialize: self.
]

{ #category : #writing }
SoilSerializer >> nextPutBoxedFloat64: aFloat [ 
	self
		nextPutByte: TypeCodeFloat;
		nextPutInteger: (aFloat at: 1);
		nextPutInteger: (aFloat at: 2)
]

{ #category : #writing }
SoilSerializer >> nextPutByte: anInteger [ 
	stream nextPut: anInteger
]

{ #category : #writing }
SoilSerializer >> nextPutByteArray: aByteArray [
	self 
		nextPutByte: TypeCodeByteArray; 
		nextPutLengthEncodedInteger: aByteArray size.
	1 to: aByteArray size do: [:i |
		self nextPutByte: (aByteArray at: i)].
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutBytesFrom: aByteArray len: length [ 
	stream nextPutAll: aByteArray 

]

{ #category : #writing }
SoilSerializer >> nextPutCharacter: aCharacter [ 
	aCharacter asciiValue > 255 ifTrue: [ self halt ].
	self 
		nextPutByte: TypeCodeCharacter; 
		nextPutByte: aCharacter asciiValue
]

{ #category : #writing }
SoilSerializer >> nextPutClass: aClass [ 

	self 
		nextPutByte: TypeCodeClass; 
		basicNextPutString: aClass name asString
]

{ #category : #writing }
SoilSerializer >> nextPutDate: aDate [ 
	self 
		nextPutByte: TypeCodeDate; 
		nextPutLengthEncodedInteger: aDate julianDayNumber - 2415386; 
		nextPutLengthEncodedInteger: aDate offset hours
]

{ #category : #writing }
SoilSerializer >> nextPutDictionary: aDictionary [ 
	self 
		nextPutByte: TypeCodeDictionary;
		nextPutLengthEncodedInteger: aDictionary size.
	aDictionary keysAndValuesDo: [:key :value |
		key soilSerialize: self.
		value soilSerialize: self ]
]

{ #category : #writing }
SoilSerializer >> nextPutFalse: aBoolean [ 
	self nextPutByte: TypeCodeFalse 
]

{ #category : #writing }
SoilSerializer >> nextPutFraction: aNumber [ 
	self
		nextPutByte: TypeCodeFraction;
		nextPutLengthEncodedInteger: aNumber numerator;
		nextPutLengthEncodedInteger: aNumber denominator
]

{ #category : #writing }
SoilSerializer >> nextPutIdentityDictionary: anIdentityDictionary [ 
	self 
		nextPutByte: TypeCodeIdentityDictionary;
		nextPutLengthEncodedInteger: anIdentityDictionary size.
	anIdentityDictionary keysAndValuesDo: [:key :value |
		key soilSerialize: self.
		value soilSerialize: self ]
]

{ #category : #writing }
SoilSerializer >> nextPutInteger: anInteger [ 
	(anInteger < 0)
		ifTrue: [ self nextPutLargeNegativeInteger: anInteger ] 
		ifFalse: [ self nextPutLargePositiveInteger: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutLargeNegativeInteger: anInteger [ 
	stream nextPutByte: TypeCodeLargeNegativeInteger.
	self nextPutLengthEncodedInteger: 0 - anInteger
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutLargePositiveInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeLargePositiveInteger;
		nextPutLengthEncodedInteger: anInteger
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutLengthEncodedInteger: anInteger [ 
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	anInteger < 128 ifTrue: [ ^ self nextPutByte: anInteger ].
	self
		nextPutByte: ((anInteger bitAnd: 127) bitOr: 128);
		nextPutLengthEncodedInteger: (anInteger bitShift: -7)
]

{ #category : #writing }
SoilSerializer >> nextPutNil: anUndefinedObject [ 
	stream nextPutByte: TypeCodeUndefined 
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutObjectType [
	self nextPutByte: TypeCodeObject 
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutPositiveInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeLargePositiveInteger;
		nextPutLengthEncodedInteger: anInteger
]

{ #category : #writing }
SoilSerializer >> nextPutString: aString [ 
	self
		nextPutByte: TypeCodeString;
		basicNextPutString: aString
]

{ #category : #writing }
SoilSerializer >> nextPutTrue: aBoolean [ 
	self nextPutByte: TypeCodeTrue 
]

{ #category : #public }
SoilSerializer >> putByte: anInteger [ 
	stream nextPutByte: anInteger 
]

{ #category : #accessing }
SoilSerializer >> rawStream: aWriteStream [ 
	stream := "SoilMemoryStream on:" aWriteStream 
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
