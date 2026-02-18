Class {
	#name : #SoilBasicMaterializer,
	#superclass : #SoilObjectCodec,
	#category : #'Soil-Serializer-Serializer/Materializer'
}

{ #category : #materializing }
SoilBasicMaterializer class >> materializeFromBytes: aByteArray [
	^ (self on: aByteArray readStream)
		materialize
]

{ #category : #'instance creation' }
SoilBasicMaterializer class >> on: aReadStream [
	^ self new 
		stream: aReadStream 
]

{ #category : #'reading - basic' }
SoilBasicMaterializer >> basicNextString [
	| string length |
	string := String new: (length := self nextLengthEncodedInteger).
	stream readInto: string startingAt: 1 count: length.
	^ string
]

{ #category : #public }
SoilBasicMaterializer >> materialize [
	^ self nextSoilObject
]

{ #category : #public }
SoilBasicMaterializer >> materializeFromBytes: aByteArray [
	^ (self stream: aByteArray readStream)
		materialize
]

{ #category : #'reading - basic' }
SoilBasicMaterializer >> nextByte [
	^ stream next
]

{ #category : #reading }
SoilBasicMaterializer >> nextByteArray: aClass [ 
	| byteArray size |
	byteArray := aClass basicNew: (size := self nextLengthEncodedInteger).
	stream readInto: byteArray startingAt: 1 count: size.
	^ byteArray
]

{ #category : #reading }
SoilBasicMaterializer >> nextCharacter [
	"call to #register: not needed as character is an immediate Object"
	^ Character value: self nextLengthEncodedInteger
]

{ #category : #reading }
SoilBasicMaterializer >> nextDate: aClass [ 
	 ^ aClass 
		julianDayNumber: 2415386 + self nextSoilObject 
		offset: (Duration minutes: self nextSoilObject)

]

{ #category : #reading }
SoilBasicMaterializer >> nextDateAndTime [
	^ DateAndTime basicNew 
		setJdn: 2415386 + self nextSoilObject  
		seconds:  self nextLengthEncodedInteger
		nano:  self nextLengthEncodedInteger 
		offset: (Duration minutes: self nextSoilObject)
]

{ #category : #reading }
SoilBasicMaterializer >> nextFloat: aClass [ 
	"We multiply the Boxedfloat by 1, this way we create a SmallFloat if possible"
  ^ BoxedFloat64 basicNew
		  at: 1 put: self nextLengthEncodedInteger;
		  at: 2 put: self nextLengthEncodedInteger;
		  * 1
]

{ #category : #reading }
SoilBasicMaterializer >> nextFraction: aClass [
	 ^ aClass
		numerator: self nextLengthEncodedInteger
		denominator: self nextLengthEncodedInteger
]

{ #category : #reading }
SoilBasicMaterializer >> nextLargeNegativeInteger [
	"Large Integers are normal objects (need to be registered), small integers are immediate"
	^ 0 - self nextLengthEncodedInteger

]

{ #category : #reading }
SoilBasicMaterializer >> nextLargePositiveInteger [
	
	^ self nextLengthEncodedInteger
]

{ #category : #'reading - basic' }
SoilBasicMaterializer >> nextLengthEncodedInteger [
	^ stream nextLengthEncodedInteger
]

{ #category : #reading }
SoilBasicMaterializer >> nextScaledDecimal: aClass [

	^ aClass new
		         setNumerator: self nextSoilObject
		         denominator: self nextLengthEncodedInteger
		         scale: self nextLengthEncodedInteger
]

{ #category : #reading }
SoilBasicMaterializer >> nextSoilObject [ 
	| byte object |

	byte := self nextByte.
	object := (TypeCodeMapping 
		at: byte
		ifAbsent: [ Error signal: 'cannot find type code for ', byte asString]) 
			soilMaterialize: self.
	^ object 
		soilMaterialized: self;
		soilMaterializationReplacement
]

{ #category : #reading }
SoilBasicMaterializer >> nextString [

	^ self basicNextString

]

{ #category : #reading }
SoilBasicMaterializer >> nextSymbol [
	| bytes length |
	length := self nextLengthEncodedInteger.
	bytes := ByteArray new: length.
	stream readInto: bytes startingAt: 1 count: length.
	^ bytes asString asSymbol
	

]

{ #category : #reading }
SoilBasicMaterializer >> nextTime [
	^ Time seconds: self nextLengthEncodedInteger nanoSeconds: self nextLengthEncodedInteger
]

{ #category : #reading }
SoilBasicMaterializer >> nextUUID: aClass [ 
	| uuid size byteArray |
	size := self nextLengthEncodedInteger.
	byteArray := SystemVersion current major < 12 
		ifTrue: [ aClass new: size] 
		ifFalse: [ ByteArray new: size].
	
	stream readInto: byteArray startingAt: 1 count: size.
	
	uuid := SystemVersion current major < 12 
		ifTrue: [byteArray ] 
		ifFalse: [UUID nilUUID uuidData: byteArray].
	
	^ uuid
]

{ #category : #reading }
SoilBasicMaterializer >> nextWideString [
	| buf length |
	buf := ByteArray new: (length := self nextLengthEncodedInteger).
	stream readInto: buf startingAt: 1 count: length.
	^ self class decodeBytes: buf
]

{ #category : #reading }
SoilBasicMaterializer >> nextWideSymbol [
	| buf len |
	buf := ByteArray new: (len := self nextLengthEncodedInteger).
	stream readInto: buf startingAt: 1 count: len.
	^ (self class decodeBytes: buf) asSymbol
]
