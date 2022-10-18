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

{ #category : #'as yet unclassified' }
SoilMaterializer >> materialize [
	^ self nextObject
]

{ #category : #'instance creation' }
SoilMaterializer >> newObject [
	self halt.
]

{ #category : #reading }
SoilMaterializer >> nextArray: aClass [ 
	| array |
	array := aClass new: self nextLengthEncodedInteger.
	self register: array.
	1 to: array size do: [ :index | array at: index put: self nextObject ].
	^ array
]

{ #category : #reading }
SoilMaterializer >> nextAssociation: aClass [ 
	| association |
	association := aClass new.
	self register: association.
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
	self register: byteArray.
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

{ #category : #reading }
SoilMaterializer >> nextLargePositiveInteger [
	^ self nextLengthEncodedInteger 
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextLengthEncodedInteger [
	| value |
	value := self nextByte.
	(value < 128) ifTrue: [ ^ value ].
	^ (self nextLengthEncodedInteger bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #'memory scanning' }
SoilMaterializer >> nextObject [ 
	^ (TypeCodeMapping at: self nextByte) soilMaterialize: self 
]

{ #category : #'as yet unclassified' }
SoilMaterializer >> nextPositiveInteger [
	^ self nextLargePositiveInteger 
]

{ #category : #materializing }
SoilMaterializer >> nextSmallFloat64: aClass [ 
	"We multiply the Boxesfloat by 1, this way we create a SmallFloat if possible"
	^ BoxedFloat64 basicNew
		  at: 1 put: self nextObject;
		  at: 2 put: self nextObject;
		  * 1
]

{ #category : #actions }
SoilMaterializer >> nextString [
	| buf len string |
	buf := ByteArray new: (len := self nextPositiveInteger).
	stream readInto: buf startingAt: 1 count: len.
	string := buf asString.
	self register: string.
	^ string

]

{ #category : #accessing }
SoilMaterializer >> rawStream: aStream [ 
	stream := aStream
]

{ #category : #registry }
SoilMaterializer >> register: anObject [
	objects ifNil: [ objects := OrderedCollection new ].
	objects add: anObject 
]
