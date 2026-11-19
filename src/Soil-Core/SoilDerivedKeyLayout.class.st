"
A SoilDerivedKeyLayout says how a SoilDerivedIndex turns the value of an indexed attribute into
the key of an index entry, and which stretch of keys holds the entries of one value. The
collection asks the layout and does not know what is stored underneath.

Every key a layout builds occupies the whole key size of the index, so the index, which packs a
key into one number of that size, neither pads it nor reorders it. Padding a short key on the left
is what makes the length dominate the order for an ordinary index key, see #asIndexKeyOfSize:.

The attribute part has a fixed width and holds the encoded value:
- ByteString and Symbol, left aligned, zeros to the right: they sort by their bytes, 'aa' before 'b'
- ByteArray, the same
- a non-negative Integer, big endian and right aligned, zeros to the left: numeric order
Everything else is an error when the key is built: nil, a WideString, a negative number, a Float, a
Date, a Boolean. So is a value that is too long for the attribute part. Nothing is cut off.

A unique layout uses the whole key size for the attribute. A non-unique layout puts the primary key
of the element behind the attribute, so the keys of two elements with the same value differ and
sort by their primary keys, also for a new element that has no object id yet. The attribute part is
then the key size minus the width of the primary key, and the entries of one value are the range from
the attribute with a primary key of all zeros to the attribute with a primary key of all ones.
"
Class {
	#name : #SoilDerivedKeyLayout,
	#superclass : #Object,
	#instVars : [
		'keySize',
		'primaryKeySize',
		'unique'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilDerivedKeyLayout class >> keySize: anInteger unique: aBoolean primaryKeySize: anotherInteger [
	^ self new
		setKeySize: anInteger unique: aBoolean primaryKeySize: anotherInteger;
		yourself
]

{ #category : #accessing }
SoilDerivedKeyLayout >> attributeSize [
	"the width of the part of a key that holds the attribute"
	^ unique
		ifTrue: [ keySize ]
		ifFalse: [ keySize - primaryKeySize ]
]

{ #category : #private }
SoilDerivedKeyLayout >> encode: aValue [
	"the attribute part of a key for aValue, always #attributeSize bytes"
	| bytes |
	aValue isNil ifTrue: [
		^ SoilUnsupportedError signal: 'nil cannot be indexed, let the getter answer a substitute value' ].
	bytes := (self isByteString: aValue)
		ifTrue: [ aValue asByteArray ]
		ifFalse: [
			aValue class == ByteArray
				ifTrue: [ aValue ]
				ifFalse: [
					(aValue isInteger and: [ aValue >= 0 ])
						ifTrue: [ ^ self encodeInteger: aValue ]
						ifFalse: [
							^ SoilUnsupportedError signal:
								aValue printString , ' (' , aValue class name
								, ') cannot be indexed, only byte strings, byte arrays and non-negative integers can' ] ] ].
	bytes size > self attributeSize ifTrue: [
		^ SoilUnsupportedError signal:
			aValue printString , ' is ' , bytes size asString , ' bytes and does not fit in '
			, self attributeSize asString , ' bytes' ].
	^ bytes , (ByteArray new: self attributeSize - bytes size)
]

{ #category : #private }
SoilDerivedKeyLayout >> encodeInteger: anInteger [
	anInteger highBit > (self attributeSize * 8) ifTrue: [
		^ SoilUnsupportedError signal:
			anInteger printString , ' does not fit in ' , self attributeSize asString , ' bytes' ].
	^ anInteger asByteArrayOfSize: self attributeSize
]

{ #category : #private }
SoilDerivedKeyLayout >> isByteString: aValue [
	^ aValue class == ByteString or: [ aValue class == ByteSymbol ]
]

{ #category : #accessing }
SoilDerivedKeyLayout >> keyFor: aValue primaryKey: aByteArray [
	"the key of the entry of the element with primary key aByteArray whose attribute is aValue,
	a ByteArray of the whole key size. A unique layout does not use the primary key"
	^ unique
		ifTrue: [ self encode: aValue ]
		ifFalse: [
			aByteArray size = primaryKeySize ifFalse: [
				^ SoilUnsupportedError signal:
					'a primary key of ' , aByteArray size asString , ' bytes does not fit behind the attribute, the layout holds '
					, primaryKeySize asString ].
			(self encode: aValue) , aByteArray ]
]

{ #category : #accessing }
SoilDerivedKeyLayout >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilDerivedKeyLayout >> primaryKeySize [
	^ primaryKeySize
]

{ #category : #printing }
SoilDerivedKeyLayout >> printOn: aStream [
	super printOn: aStream.
	aStream
		<< ' keySize=';
		print: keySize;
		<< (unique ifTrue: [ ' unique' ] ifFalse: [ ' non-unique' ])
]

{ #category : #accessing }
SoilDerivedKeyLayout >> rangeFor: aValue [
	"the keys of all entries whose attribute is aValue. For a non-unique layout that is
	the attribute with a primary key of all zeros up to the attribute with a primary key of all ones,
	for a unique layout the single key of aValue"
	^ SoilPrefixRange
		prefix: (self encode: aValue) asInteger
		width: self attributeSize
		keySize: keySize
]

{ #category : #initialization }
SoilDerivedKeyLayout >> setKeySize: anInteger unique: aBoolean primaryKeySize: anotherInteger [
	(aBoolean not and: [ anInteger <= anotherInteger ]) ifTrue: [
		^ SoilUnsupportedError signal:
			'a key size of ' , anInteger asString
			, ' leaves no room for an attribute in front of a primary key of ' , anotherInteger asString , ' bytes' ].
	keySize := anInteger.
	unique := aBoolean.
	primaryKeySize := anotherInteger
]

{ #category : #testing }
SoilDerivedKeyLayout >> isUnique [
	^ unique
]
