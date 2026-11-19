"
A SoilKeyEncoding says how the value of a property is put into bytes, and with that what equality
and order of values are. An index keeps the encoded bytes, a read without an index compares through
the same encoding, so the two can never disagree. It is used without a width to compare and with a
width to build the attribute part of a key, see SoilDerivedKeyLayout.

This is the standard encoding, exact: nothing is cut off, a value that does not fit the width is an
error.
- ByteString and Symbol: their bytes, left aligned, zeros to the right. They order by their bytes,
  'aa' before 'b', not by their length.
- ByteArray: the same.
- a non-negative Integer: big endian, right aligned, zeros to the left. They order numerically.
Everything else is an error with the value in the message: nil, a WideString, a negative number, a
Float, a Date, a Boolean. A SoilUnsupportedError, whether the value is put into an index or only
compared.

Two values are equal when they compare equal, and they compare as the bytes they are encoded to at
the width of the longer of them. That is the order of an index, whose width is larger than both.
"
Class {
	#name : #SoilKeyEncoding,
	#superclass : #Object,
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilKeyEncoding class >> standard [
	^ self new
]

{ #category : #comparing }
SoilKeyEncoding >> compare: aValue with: anotherValue [
	"-1, 0 or 1: how aValue orders against anotherValue"
	| width mine other |
	width := (self naturalSizeOf: aValue) max: (self naturalSizeOf: anotherValue).
	mine := self encode: aValue width: width.
	other := self encode: anotherValue width: width.
	1 to: width do: [ :each |
		(mine at: each) = (other at: each) ifFalse: [
			^ (mine at: each) < (other at: each) ifTrue: [ -1 ] ifFalse: [ 1 ] ] ].
	^ 0
]

{ #category : #encoding }
SoilKeyEncoding >> encode: aValue width: anInteger [
	"the bytes of aValue, exactly anInteger of them"
	| bytes |
	aValue isNil ifTrue: [
		^ SoilUnsupportedError signal: 'nil cannot be indexed, let the getter answer a substitute value' ].
	(self isBytesLike: aValue) ifTrue: [
		bytes := aValue asByteArray.
		bytes size > anInteger ifTrue: [
			^ SoilUnsupportedError signal:
				aValue printString , ' is ' , bytes size asString , ' bytes and does not fit in '
				, anInteger asString , ' bytes' ].
		^ bytes , (ByteArray new: anInteger - bytes size) ].
	(aValue isInteger and: [ aValue >= 0 ]) ifTrue: [
		aValue highBit > (anInteger * 8) ifTrue: [
			^ SoilUnsupportedError signal:
				aValue printString , ' does not fit in ' , anInteger asString , ' bytes' ].
		^ aValue asByteArrayOfSize: anInteger ].
	^ SoilUnsupportedError signal:
		aValue printString , ' (' , aValue class name
		, ') cannot be indexed, only byte strings, byte arrays and non-negative integers can'
]

{ #category : #testing }
SoilKeyEncoding >> isBytesLike: aValue [
	"a value stored left aligned: a byte string, a symbol or a byte array"
	^ aValue class == ByteString or: [ aValue class == ByteSymbol or: [ aValue class == ByteArray ] ]
]

{ #category : #comparing }
SoilKeyEncoding >> isValue: aValue startingWith: someBytes [
	"whether the encoded bytes of aValue begin with someBytes, which are bytes or a string. Only
	a value that is stored left aligned has leading bytes of its own"
	| width |
	(self isBytesLike: aValue) ifFalse: [
		^ SoilUnsupportedError signal:
			aValue printString , ' has no front to compare, only byte strings and byte arrays have' ].
	width := aValue size max: someBytes size.
	^ ((self encode: aValue width: width) first: someBytes size) = (self encode: someBytes width: someBytes size)
]

{ #category : #private }
SoilKeyEncoding >> naturalSizeOf: aValue [
	"how many bytes aValue takes up unpadded"
	^ (aValue isInteger and: [ aValue >= 0 ])
		ifTrue: [ (aValue highBit + 7) // 8 max: 1 ]
		ifFalse: [
			(self isBytesLike: aValue)
				ifTrue: [ aValue size ]
				ifFalse: [ 1 ] ]
]
