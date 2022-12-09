Class {
	#name : #SoilMaterializer,
	#superclass : #SoilObjectCodec,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Serialization'
}

{ #category : #'as yet unclassified' }
SoilMaterializer class >> materializeFromBytes: aByteArray [
	^ (self on: aByteArray readStream)
		materialize
]

{ #category : #'as yet unclassified' }
SoilMaterializer class >> on: aReadStream [
	^ self new 
		stream: aReadStream 
]

{ #category : #'reading - basic' }
SoilMaterializer >> basicNextString [
	| buf length |
	buf := ByteArray new: (length := self nextLengthEncodedInteger).
	stream readInto: buf startingAt: 1 count: length.
	^ buf asString
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> materialize [
	^ self nextSoilObject
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> materializeFromBytes: aByteArray [
	^ (self stream: aByteArray readStream)
		materialize
]

{ #category : #'instance creation' }
SoilMaterializer >> newObject [
	| objectClass description objectIndex|
	objectIndex := self nextLengthEncodedInteger.
	description := objectIndex isZero
		ifTrue: [ SOClassDescription meta ]
		ifFalse: [
			transaction 
				classDescriptionWithId: (externalObjectRegistry basicReferenceAt: objectIndex) 
				ifNone: [ self halt  ] ].
	objectClass := description objectClass.
	^ objectClass classLayout soilBasicMaterialize: objectClass with: self
]

{ #category : #reading }
SoilMaterializer >> nextArray: aClass [ 
	| array |
	array := aClass new: self nextLengthEncodedInteger.
	self registerObject: array.
	1 to: array size do: [ :index | array at: index put: self nextSoilObject ].
	^ array
]

{ #category : #reading }
SoilMaterializer >> nextAssociation: aClass [ 
	| association |
	association := aClass new.
	self registerObject: association.
	^ association
		key: self nextSoilObject;
		value: self nextSoilObject
]

{ #category : #'reading - basic' }
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
SoilMaterializer >> nextByteCharacter [
	"call to #register: not needed as character is an immediate Object"
	^ Character codePoint: self nextByte
]

{ #category : #reading }
SoilMaterializer >> nextCharacter [
	"call to #register: not needed as character is an immediate Object"
	^ Character value: self nextLengthEncodedInteger
]

{ #category : #reading }
SoilMaterializer >> nextClass [
	^ Smalltalk 
		at: self nextString asSymbol 
		ifAbsent: nil
]

{ #category : #reading }
SoilMaterializer >> nextCompiledBlock: aClass [

 	| header bytecodesSize compiledBlock |

 	header := self nextSoilObject.
 	bytecodesSize := self nextLengthEncodedInteger.
	
 	compiledBlock := aClass
 		newMethod: bytecodesSize
 		header: header.
	
	self registerObject: compiledBlock.

 	"first the literals"
 	"note: we store the outer method here as a copy, more thinking needed"
 	1 to: compiledBlock numLiterals do: [:i | 
 				compiledBlock literalAt: i put: self nextSoilObject ].			

 	compiledBlock initialPC 
 		to: compiledBlock size
 		do: [ :index |
 			compiledBlock
 				at: index
 				put: self nextByte ].

 	^compiledBlock
]

{ #category : #reading }
SoilMaterializer >> nextCompiledMethod: aClass [

 	| header bytecodesPlusTrailerSize compiledMethod |

 	header :=  self nextSoilObject.
 	bytecodesPlusTrailerSize := self nextLengthEncodedInteger.

 	compiledMethod := aClass
 		newMethod: bytecodesPlusTrailerSize
 		header: header.

	self registerObject: compiledMethod.

 	"first the literals"	
 	"for now we do store the class pointer in the last literal"	
 	1 to: compiledMethod numLiterals do: [:i | 
 				compiledMethod literalAt: i  put: self nextSoilObject ].			

 	"then the bytecodes, we ignore the trailer for now"
 	compiledMethod initialPC 
 		to: compiledMethod size - compiledMethod trailer size
 		do: [ :index |
 			compiledMethod
 				at: index
 				put: self nextByte ].
	
 	^compiledMethod
]

{ #category : #reading }
SoilMaterializer >> nextDate: aClass [
	| startJdn startSeconds startNano offsetSeconds offsetNanos dateStart date |

	startJdn := self nextLengthEncodedInteger.
	startSeconds := self nextLengthEncodedInteger.
	"startNano := self nextLengthEncodedInteger".
	offsetSeconds := self nextLengthEncodedInteger.
	"offsetNanos := self nextLengthEncodedInteger".
	dateStart := DateAndTime basicNew
		setJdn: startJdn
		seconds: startSeconds
		nano: "startNano" 0
		offset: (Duration seconds: offsetSeconds - 86400 nanoSeconds: "offsetNanos" 0);
		yourself.

	date := aClass starting: dateStart.
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
		key := self nextSoilObject.
		dict at: key put: self nextSoilObject.
	].
	^dict
]

{ #category : #reading }
SoilMaterializer >> nextExternalReference [
	| index |
	index := self nextLengthEncodedInteger.
	^ externalObjectRegistry referenceAt: index
]

{ #category : #reading }
SoilMaterializer >> nextFloat: aClass [ 
	"We multiply the Boxedfloat by 1, this way we create a SmallFloat if possible"
	| float |
	float :=  BoxedFloat64 basicNew
		  at: 1 put: self nextLengthEncodedInteger;
		  at: 2 put: self nextLengthEncodedInteger;
		  * 1.
	"Boxedfloat is a normal object (needs to be registered), SmallFloat is immediate"
	float isImmediateObject ifFalse: [self registerObject: float].
	^float
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

{ #category : #reading }
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
	integer isImmediateObject ifFalse: [ self registerObject: integer].
	^integer
]

{ #category : #reading }
SoilMaterializer >> nextLargePositiveInteger [
	| integer |
	integer := self nextLengthEncodedInteger.
	integer isImmediateObject ifFalse: [ self registerObject: integer].
	^integer
]

{ #category : #'reading - basic' }
SoilMaterializer >> nextLengthEncodedInteger [
	| value |
	value := self nextByte.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #reading }
SoilMaterializer >> nextMessage: aClass [ 
	| message |
	message := aClass new.
	self registerObject: message.
	^ message
		setSelector: self nextSoilObject arguments: self nextSoilObject;
		yourself
]

{ #category : #reading }
SoilMaterializer >> nextMessageSend: aClass [

	| messageSend |
	messageSend := aClass new.
	self registerObject: messageSend.
	^ messageSend
		  receiver: self nextSoilObject;
		  selector: self nextSoilObject;
		  arguments: self nextSoilObject;
		  yourself
]

{ #category : #reading }
SoilMaterializer >> nextOrderedCollection: aClass [ 
		| size collection |
	size := self  nextLengthEncodedInteger.
	collection := aClass new: size.
	self registerObject: collection.
	size timesRepeat: [ collection addLast: self nextSoilObject ].
	^ collection
]

{ #category : #reading }
SoilMaterializer >> nextScaledDecimal: aClass [

	| scaledDecimal |
	scaledDecimal := aClass new
		                 setNumerator: self nextLengthEncodedInteger
		                 denominator: self nextLengthEncodedInteger
		                 scale: self nextLengthEncodedInteger.
	self registerObject: scaledDecimal.
	^ scaledDecimal
]

{ #category : #reading }
SoilMaterializer >> nextSoilObject [ 
	^ (TypeCodeMapping at: self nextByte) soilMaterialize: self 
]

{ #category : #reading }
SoilMaterializer >> nextString [
	| string |
	string := self basicNextString.
	self registerObject: string.
	^ string

]

{ #category : #reading }
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

{ #category : #registry }
SoilMaterializer >> registerObject: anObject [
	objects ifNil: [ objects := OrderedCollection new ].
	objects add: anObject 
]

{ #category : #accessing }
SoilMaterializer >> soil [

	^ soil
]

{ #category : #accessing }
SoilMaterializer >> soil: anObject [

	soil := anObject
]

{ #category : #accessing }
SoilMaterializer >> stream [
	^stream
]
