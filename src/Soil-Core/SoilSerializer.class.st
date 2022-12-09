Class {
	#name : #SoilSerializer,
	#superclass : #SoilObjectCodec,
	#instVars : [
		'clusterRoot',
		'soil'
	],
	#category : #'Soil-Core-Serialization'
}

{ #category : #'instance creation' }
SoilSerializer class >> on: aStream [ 
	^ self new 
		stream: aStream 
]

{ #category : #public }
SoilSerializer class >> serializeToBytes: anObject [ 

	^ (self on: ByteArray new writeStream) 
		serialize: anObject

]

{ #category : #'writing - basic' }
SoilSerializer >> basicNextPutString: aString [ 
	| buf |
	buf := aString asByteArray.
	self
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf
]

{ #category : #writing }
SoilSerializer >> basicNextPutSymbol: aSymbol [ 
	self
		nextPutLengthEncodedInteger: aSymbol size;
		nextPutBytesFrom: aSymbol asByteArray
]

{ #category : #public }
SoilSerializer >> classDescriptionFor: aClass [ 
	^ transaction classDescriptionFor: aClass
]

{ #category : #initialization }
SoilSerializer >> initialize [ 
	super initialize.
	objects := OrderedCollection new
]

{ #category : #writing }
SoilSerializer >> nextPutArray: anArray [ 
	self 
		nextPutByte: TypeCodeArray;
		nextPutLengthEncodedInteger: anArray size.
	1 to: anArray size do: [:i | 
		(anArray at: i) soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutAssociation: anAssociation [ 
	self nextPutByte: TypeCodeAssociation.
	anAssociation key soilSerialize: self.
	anAssociation value soilSerialize: self.
]

{ #category : #'writing - basic' }
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

{ #category : #'writing - basic' }
SoilSerializer >> nextPutBytesFrom: aByteArray [
	stream nextPutAll: aByteArray 

]

{ #category : #writing }
SoilSerializer >> nextPutCharacter: aCharacter [
	"we store 8bit characters with TypeCodeByteCharacter to save some space"
	| charAsInteger |
	charAsInteger := aCharacter asInteger.
	self nextPutByte: (charAsInteger > 255
			 ifTrue: [ TypeCodeCharacter ]
			 ifFalse: [ TypeCodeByteCharacter ]).
	self nextPutLengthEncodedInteger: charAsInteger
]

{ #category : #writing }
SoilSerializer >> nextPutClass: aClass [ 

	self 
		nextPutByte: TypeCodeClass; 
		basicNextPutString: aClass name asString
]

{ #category : #writing }
SoilSerializer >> nextPutCompiledBlock: aCompiledMethod [
	
	| bytecodesPlusTrailerSize |
	bytecodesPlusTrailerSize := aCompiledMethod size
	                            - aCompiledMethod initialPC + 1.

	self
		nextPutByte: TypeCodeCompiledBlock;
		nextPutInteger: aCompiledMethod header;
		nextPutLengthEncodedInteger: bytecodesPlusTrailerSize.
	"literals"
	"Here we have to take care about outer code: for now we will serialize it"

	1 to: aCompiledMethod numLiterals do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	"variable part"
	(SystemVersion current major == 11)
	ifTrue: [self nextPutBytesFrom: aCompiledMethod bytecodes  ]
	ifFalse: [ self nextPutBytesFrom: aCompiledMethod bytecode ]
	
]

{ #category : #writing }
SoilSerializer >> nextPutCompiledMethod: aCompiledMethod [

	| bytecodesPlusTrailerSize |
	bytecodesPlusTrailerSize := aCompiledMethod size
	                            - aCompiledMethod initialPC + 1.

	self
		nextPutByte: TypeCodeCompiledMethod;
		nextPutInteger: aCompiledMethod header;
		nextPutLengthEncodedInteger: bytecodesPlusTrailerSize.
	"literals"
	"for now we do store the class pointer in the last literal"
	1 to: aCompiledMethod numLiterals do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	"variable part"
		(SystemVersion current major == 11)
	ifTrue: [self nextPutBytesFrom: aCompiledMethod bytecodes  ]
	ifFalse: [ self nextPutBytesFrom: aCompiledMethod bytecode ]
]

{ #category : #writing }
SoilSerializer >> nextPutDate: aDate [
	"Save a Date representation.
	In Pharo a Date is actually a TimeSpan of 24 hours from a starting DateAndTime.
	The start of the Date is a DateAndTime, which will be stored as four integers:
		julianDayNumber
		seconds
		nanos
		offset 
	The offset is a Duration, so store the seconds and nanos.
	The offset can be negative, so normalize it to positive by adding 1 day asSeconds = 86400.
	The TimeSpan duration of a day is always 24 hours, so no need to store it."

	| dateStart |

	dateStart := aDate start.

	"self
		nextPutByte: TypeCodeDate;
		nextPutLengthEncodedInteger: dateStart julianDayNumberUTC;
		nextPutLengthEncodedInteger: dateStart secondsSinceMidnightUTC;
		nextPutLengthEncodedInteger: dateStart nanoSecond;
		nextPutLengthEncodedInteger: dateStart offset asSeconds + 86400;
		nextPutLengthEncodedInteger: dateStart offset nanoSeconds"
	self
		nextPutByte: TypeCodeDate;
		nextPutLengthEncodedInteger: dateStart julianDayNumberUTC;
		nextPutLengthEncodedInteger: dateStart secondsSinceMidnightUTC;
		nextPutLengthEncodedInteger: dateStart offset asSeconds + 86400
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

{ #category : #registry }
SoilSerializer >> nextPutExternalReference: anInteger [
	self 
		nextPutByte: TypeCodeExternalReference; 
		nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilSerializer >> nextPutFalse: aBoolean [ 
	self nextPutByte: TypeCodeFalse 
]

{ #category : #writing }
SoilSerializer >> nextPutFloat: aFloat [ 
	self
		nextPutByte: TypeCodeFloat;
		nextPutLengthEncodedInteger: (aFloat at: 1);
		nextPutLengthEncodedInteger: (aFloat at: 2)
]

{ #category : #writing }
SoilSerializer >> nextPutFraction: aNumber [
	"we know that numerator and denominator are SmallIntegers"
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

{ #category : #writing }
SoilSerializer >> nextPutInternalReference: anInteger [ 
	self 
		nextPutByte: TypeCodeInternalReference; 
		nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilSerializer >> nextPutLargeNegativeInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeLargeNegativeInteger;
		nextPutLengthEncodedInteger: 0 - anInteger
]

{ #category : #writing }
SoilSerializer >> nextPutLargePositiveInteger: anInteger [ 
	self 
		nextPutByte: TypeCodeLargePositiveInteger;
		nextPutLengthEncodedInteger: anInteger
]

{ #category : #'writing - basic' }
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

{ #category : #writing }
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

{ #category : #writing }
SoilSerializer >> nextPutProcessorScheduler: aProcessorScheduler [ 
	self nextPutByte: TypeCodeProcessScheduler 
]

{ #category : #writing }
SoilSerializer >> nextPutScaledDecimal: aNumber [
	"we know that numerator, denominator and scale are SmallIntegers"
	self
		nextPutByte: TypeCodeScaledDecimal;
		nextPutLengthEncodedInteger: aNumber numerator;
		nextPutLengthEncodedInteger: aNumber denominator;
		nextPutLengthEncodedInteger: aNumber scale 
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
		basicNextPutSymbol: aSymbol
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
	buf := self class encodeString: aWideString.
	self
		nextPutByte: TypeCodeWideString;
		nextPutLengthEncodedInteger: buf size;
		nextPutBytesFrom: buf
]

{ #category : #writing }
SoilSerializer >> nextPutWideSymbol: aSymbol [
	| buf |
	buf := aSymbol asString utf8Encoded.
	self
		nextPutByte: TypeCodeWideSymbol;
		nextPutLengthEncodedInteger:  buf size;
		nextPutBytesFrom: buf
]

{ #category : #writing }
SoilSerializer >> notSupportedError: anObject [ 
	Error signal: 'serialization of class ', anObject class name asString , ' is not supported'
]

{ #category : #'as yet unclassified' }
SoilSerializer >> referenceIndexOf: aSOClassDescription [ 
	^ externalObjectRegistry indexOf: aSOClassDescription 
]

{ #category : #registry }
SoilSerializer >> registerObject: anObject ifAbsent: aBlock [
	| index externalIndex |
	(anObject == clusterRoot) ifTrue: [ 
		"later references could reference the cluster root so we put
		it as first object to be able to have an internal reference to it"
		objects add: anObject.
		^ aBlock value ]. 
	index := objects indexOf: anObject.
	(index > 0) ifTrue: [ 
		self nextPutInternalReference: index.
		^ self ].
	externalIndex := externalObjectRegistry
		ifNotNil: [ externalObjectRegistry indexOf: anObject ]
		ifNil: [
			"if there is no external object repository we cannot
			resolve external objects, hence we treat them as  
			internal. This might be too dangerous later and might
			be removed" 
			0 ].
	((anObject == clusterRoot) not and: [ externalIndex > 0 ])
		ifTrue: [ 
			self nextPutExternalReference: externalIndex ]
		ifFalse: [  
			objects add: anObject.
			aBlock value ] 

]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	clusterRoot := anObject.
	clusterRoot soilSerialize: self.
	stream flush.
	^ stream contents
]

{ #category : #public }
SoilSerializer >> serializeToBytes: anObject [ 

	^ (self stream: ByteArray new writeStream) 
		serialize: anObject

]

{ #category : #accessing }
SoilSerializer >> soil: aSoil [ 
	soil := aSoil 
]
