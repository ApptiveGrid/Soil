Class {
	#name : #SoilMaterializer,
	#superclass : #SoilObjectCodec,
	#instVars : [
		'stream',
		'objects'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SoilMaterializer class >> materializeFromBytes: aByteArray [
	^ self new 
		rawStream: aByteArray readStream;
		materialize
]

{ #category : #actions }
SoilMaterializer >> basicNextString [
	| buf length |
	buf := ByteArray new: (length := self nextPositiveInteger).
	stream readInto: buf startingAt: 1 count: length.
	^ buf asString
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> materialize [
	^ self nextObject
]

{ #category : #'instance creation' }
SoilMaterializer >> newObject [
	| name object basicSize iSize objectClass |
	name := self basicNextString .
	objectClass := Smalltalk at: name asSymbol.
	objectClass isVariable 
		ifTrue: [ object := objectClass basicNew: (basicSize := self nextLengthEncodedInteger) ]
		ifFalse: [
			basicSize := 0.
			object := objectClass basicNew.
		].
	self registerObject: object.
	object class isBytes ifTrue: [
		objectClass isWords 
			ifTrue: [1 to: basicSize do: [:i | object basicAt: i put: stream primitive getInteger]]
			ifFalse: [ stream readInto: object startingAt: 1 count: basicSize ].
		^object
	].
	iSize := "classInfo realInstSize" object class allInstVarNames size.
	1 to: iSize do: [:i | object instVarAt: i put: (self nextObject) ].
	iSize + 1 to: iSize + basicSize do: [:i | object instVarAt: i put: self nextObject ].
	object soilMaterialized: self.
	^ object
	
]

{ #category : #reading }
SoilMaterializer >> nextArray: aClass [ 
	| array |
	array := aClass new: self nextLengthEncodedInteger.
	self registerObject: array.
	1 to: array size do: [ :index | array at: index put: self nextObject ].
	^ array
]

{ #category : #reading }
SoilMaterializer >> nextAssociation: aClass [ 
	| association |
	association := aClass new.
	self registerObject: association.
	^ association
		key: self nextObject;
		value: self nextObject
]

{ #category : #accessing }
SoilMaterializer >> nextByte [
	^ stream next
]

{ #category : #reading }
SoilMaterializer >> nextByteArray: aClass [ 
	| byteArray |
	byteArray := aClass new: self nextLengthEncodedInteger.
	self registerObject: byteArray.
	1 to: byteArray size do: [:i | 
		byteArray 
			at: i 
			put: self nextByte ].
	^byteArray
]

{ #category : #reading }
SoilMaterializer >> nextCharacter [
	^ Character codePoint: self nextByte
]

{ #category : #reading }
SoilMaterializer >> nextClass [
	^ Smalltalk 
		at: self nextString asSymbol 
		ifAbsent: nil
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextDate [
	self shouldBeImplemented.
]

{ #category : #reading }
SoilMaterializer >> nextDate: aClass [ 
	| date |
	date := aClass 
		julianDayNumber: 2415386 + self nextLengthEncodedInteger 
		offset: (Duration hours: self nextLengthEncodedInteger).
	self registerObject: date.
	^ date
]

{ #category : #reading }
SoilMaterializer >> nextDictionary: aClass [ 
	| size dict key |
	size := self nextLengthEncodedInteger.
	dict := aClass new: size.
	self registerObject: dict.
	size timesRepeat: [
		key := self nextObject.
		dict at: key put: self nextObject.
	].
	^dict
]

{ #category : #reading }
SoilMaterializer >> nextFraction: aClass [ 
	| fraction |
	fraction := aClass
		numerator: self nextLengthEncodedInteger
		denominator: self nextLengthEncodedInteger.
	self registerObject: fraction.
	^ fraction
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextIdentityDictionary: aClass [ 
	self shouldBeImplemented.
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextInternalReference [
	| index |
	index := self nextLengthEncodedInteger.
	^ objects at: index
]

{ #category : #reading }
SoilMaterializer >> nextLargeNegativeInteger [
	| integer |
	"Large Integers are normal objects (need to be registered), small integers are immediate"
	integer := 0 - self nextLengthEncodedInteger.
	^ integer isLarge
		  ifTrue: [ 
			self registerObject: integer.
			integer ]
		  ifFalse: [ integer ]
]

{ #category : #reading }
SoilMaterializer >> nextLargePositiveInteger [
	| integer |
	integer := self nextLengthEncodedInteger.
	^ integer isLarge
	  ifTrue: [ 
		self registerObject: integer.
		integer ]
	  ifFalse: [ integer ]
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextLengthEncodedInteger [
	| value |
	value := self nextByte.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #reading }
SoilMaterializer >> nextMessage: aClass [ 
		| result message |
	message := aClass new.
	self registerObject: message.
	^ message
		setSelector: self nextObject arguments: self nextObject;
		yourself
]

{ #category : #reading }
SoilMaterializer >> nextMessageSend: aClass [ 
		| result messageSend |
	messageSend := aClass new.
	self registerObject: messageSend.
	^ messageSend
		receiver: self nextObject;
		selector: self nextObject;
		arguments: self nextObject;
		yourself
]

{ #category : #'memory scanning' }
SoilMaterializer >> nextObject [ 
	^ (TypeCodeMapping at: self nextByte) soilMaterialize: self 
]

{ #category : #reading }
SoilMaterializer >> nextOrderedCollection: aClass [ 
		| size collection |
	size := self  nextLengthEncodedInteger.
	collection := aClass new: size.
	self registerObject: collection.
	size timesRepeat: [ collection addLast: self nextObject ].
	^ collection
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextPositiveInteger [
	^ self nextLargePositiveInteger 
]

{ #category : #materializing }
SoilMaterializer >> nextSmallFloat64: aClass [ 
	"We multiply the Boxesfloat by 1, this way we create a SmallFloat if possible"
	^ BoxedFloat64 basicNew
		  at: 1 put: self nextLengthEncodedInteger;
		  at: 2 put: self nextLengthEncodedInteger;
		  * 1
]

{ #category : #actions }
SoilMaterializer >> nextString [
	| string |
	string := self basicNextString.
	self registerObject: string.
	^ string

]

{ #category : #actions }
SoilMaterializer >> nextSymbol [
	| bytes length |
	length := self nextLengthEncodedInteger.
	bytes := ByteArray new: length.
	stream readInto: bytes startingAt: 1 count: length.
	^ bytes asString asSymbol
	

]

{ #category : #reading }
SoilMaterializer >> nextTime [
	| time |
	time := Time fromSeconds: self nextLengthEncodedInteger.
	self registerObject: time.
	^ time
]

{ #category : #reading }
SoilMaterializer >> nextWideString [
	| buf length wideString |
	length := self nextLengthEncodedInteger.
	buf := ByteArray new: length.
	stream readInto: buf startingAt: 1 count: length.
	wideString := self class decodeBytes: buf. 
	self registerObject: wideString. 
	^ wideString
]

{ #category : #reading }
SoilMaterializer >> nextWideSymbol [
	| buf len |
	buf := ByteArray new: (len := self nextLengthEncodedInteger).
	stream readInto: buf startingAt: 1 count: len.
	^ buf utf8Decoded asSymbol
]

{ #category : #accessing }
SoilMaterializer >> rawStream: aStream [ 
	stream := aStream
]

{ #category : #registry }
SoilMaterializer >> registerObject: anObject [
	objects ifNil: [ objects := OrderedCollection new ].
	objects add: anObject 
]
