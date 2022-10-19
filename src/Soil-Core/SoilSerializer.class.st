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
		nextPutLengthEncodedInteger: (aFloat at: 1);
		nextPutLengthEncodedInteger: (aFloat at: 2)
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
	self nextPutByte: TypeCodeLargeNegativeInteger.
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
SoilSerializer >> nextPutMessage: aMessage [ 
	self nextPutByte: TypeCodeMessage.
	aMessage selector soilSerialize: self.
	aMessage arguments soilSerialize: self
]

{ #category : #writing }
SoilSerializer >> nextPutMessageSend: aMessageSend [ 
	self nextPutByte: TypeCodeMessageSend.
	aMessageSend receiver soilSerialize: self.
	aMessageSend selector soilSerialize: self.
	aMessageSend arguments soilSerialize: self
]

{ #category : #writing }
SoilSerializer >> nextPutNil: anUndefinedObject [ 
	self nextPutByte: TypeCodeUndefined 
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutObjectType [
	self nextPutByte: TypeCodeObject 
]

{ #category : #writing }
SoilSerializer >> nextPutOrderedCollection: aCollection [ 
	self
		nextPutByte: TypeCodeOrderedCollection;
		nextPutLengthEncodedInteger: aCollection size.
	aCollection do: [:each | each soilSerialize: self ].
]

{ #category : #'as yet unclassified' }
SoilSerializer >> nextPutPositiveInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeLargePositiveInteger;
		nextPutLengthEncodedInteger: anInteger
]

{ #category : #writing }
SoilSerializer >> nextPutProcessorScheduler: aProcessorScheduler [ 
	self nextPutByte: TypeCodeProcessScheduler 
]

{ #category : #writing }
SoilSerializer >> nextPutSmallFloat64: aFloat [ 
	self
		nextPutByte: TypeCodeSmallFloat64;
		nextPutLengthEncodedInteger: (aFloat at: 1);
		nextPutLengthEncodedInteger: (aFloat at: 2)
]

{ #category : #writing }
SoilSerializer >> nextPutString: aString [ 
	self
		nextPutByte: TypeCodeString;
		basicNextPutString: aString
]

{ #category : #writing }
SoilSerializer >> nextPutSymbol: aSymbol [ 
	self
		nextPutByte: TypeCodeSymbol;
		nextPutLengthEncodedInteger: aSymbol size;
		nextPutBytesFrom: aSymbol asByteArray len: aSymbol size
]

{ #category : #writing }
SoilSerializer >> nextPutSystemDictionary: aCollection [ 
	self nextPutByte: TypeCodeSystemDictionary 
]

{ #category : #writing }
SoilSerializer >> nextPutTime: aTime [ 
	self
		nextPutByte: TypeCodeTime;
		nextPutLengthEncodedInteger: aTime asSeconds
]

{ #category : #writing }
SoilSerializer >> nextPutTrue: aBoolean [ 
	self nextPutByte: TypeCodeTrue 
]

{ #category : #writing }
SoilSerializer >> nextPutWideString: aWideString [ 
		| buf |
	buf := aWideString utf8Encoded. "self class encodeString: aWideString."
	self
		nextPutByte: TypeCodeWideString;
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf len: buf size
]

{ #category : #writing }
SoilSerializer >> nextPutWideSymbol: aSymbol [
	| buf |
	buf := aSymbol asString utf8Encoded.
	self
		nextPutByte: TypeCodeWideSymbol;
		nextPutLengthEncodedInteger:  buf size;
		nextPutBytesFrom: buf len: buf size
]

{ #category : #'as yet unclassified' }
SoilSerializer >> notSupportedError: anObject [ 
	Error signal: 'serialization of class ', anObject class name asString , ' is not supported'
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
SoilSerializer >> registerObject: anObject [
	objects ifNil: [ objects := Set new ].
	(objects includes: anObject) ifTrue: [ self halt ].
	objects add: anObject  
]

{ #category : #registry }
SoilSerializer >> registerObject: anObject ifAbsent: aBlock [
	objects ifNil: [ objects := Set new ].
	(objects includes: anObject) ifFalse: [
			objects add: anObject.
			aBlock value ]

]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	rootObject := anObject.
	rootObject soilSerialize: self.
	stream flush.
	^ stream contents
]
