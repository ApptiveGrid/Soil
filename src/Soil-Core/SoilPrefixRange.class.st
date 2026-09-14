"
The section of an index that a fixed number of leading bytes marks off. Several
independent structures can then live on one index -- a namespace each, told apart by the
marker in front of every key.

The encoding of that marker lives here, on my class side, and in both directions: out of
a marker a section, out of a key its marker. Implemented apart they would drift.

Three things follow from how an index stores a key, and getting any of them wrong is
silent rather than loud:

A key is packed into *one number* of the index's key size, so a shorter key is padded on
the *left* and its marker slides out of the front into marker 0. Every key I build
therefore occupies the full key size: my marker first, the caller's bytes after it, zero
padding last.

The marker occupies a fixed width, big endian, so that numeric order and byte order
agree. The width is not mine to pick: only the application knows how many sections it
will ever need, and the width has to stand when the index is created, because it is part
of the key size that cannot grow afterwards.

The width may be 0. Then there is no namespace, the structure has the index to itself,
and it pays no byte for the privilege.
"
Class {
	#name : #SoilPrefixRange,
	#superclass : #SoilIndexRange,
	#instVars : [
		'prefix',
		'width'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilPrefixRange class >> prefix: anInteger width: widthInBytes keySize: keySizeInBytes [
	"the one direction: out of a marker the section it stands for"

	^ self new
		setPrefix: anInteger
		width: widthInBytes
		keySize: keySizeInBytes
]

{ #category : #accessing }
SoilPrefixRange class >> prefixIn: aKey width: widthInBytes keySize: keySizeInBytes [
	"and the other: out of a key the marker it carries. Here rather than on an instance,
	because whoever holds a key and asks this has no section yet -- that is what is being
	asked"

	widthInBytes = 0 ifTrue: [ ^ 0 ].
	^ (((aKey asIndexKeyOfSize: keySizeInBytes) asByteArrayOfSize: keySizeInBytes)
		first: widthInBytes) asInteger
]

{ #category : #accessing }
SoilPrefixRange >> firstKey [

	^ self prefixBytes , (ByteArray new: keySize - width)
]

{ #category : #accessing }
SoilPrefixRange >> keyWith: aByteArray [
	"a full key inside me, built the only way the scheme survives: my marker first, the
	caller's bytes after it, zero padding last"

	aByteArray size > (keySize - width) ifTrue: [
		^ self error: 'a key of ' , aByteArray size asString
			, ' bytes does not fit behind a marker of ' , width asString
			, ' in a key size of ' , keySize asString ].
	^ self prefixBytes , aByteArray
		, (ByteArray new: keySize - width - aByteArray size)
]

{ #category : #accessing }
SoilPrefixRange >> lastKey [

	^ self prefixBytes , (ByteArray new: keySize - width withAll: 255)
]

{ #category : #accessing }
SoilPrefixRange >> prefix [
	"my marker, as the number it is written as"

	^ prefix
]

{ #category : #accessing }
SoilPrefixRange >> prefixBytes [
	"my marker in the fixed width it occupies at the front of every key of mine. A width of
	0 means there is no marker, and no number fits into no bytes -- not even zero"

	^ width = 0
		ifTrue: [ ByteArray new: 0 ]
		ifFalse: [ prefix asByteArrayOfSize: width ]
]

{ #category : #printing }
SoilPrefixRange >> printOn: aStream [

	super printOn: aStream.
	aStream
		<< ' prefix=';
		print: prefix;
		<< ' width=';
		print: width;
		<< ' keySize=';
		print: keySize
]

{ #category : #initialization }
SoilPrefixRange >> setPrefix: anInteger width: widthInBytes keySize: keySizeInBytes [

	widthInBytes < 0 ifTrue: [ ^ self error: 'a marker cannot be narrower than nothing' ].
	widthInBytes > keySizeInBytes ifTrue: [
		^ self error: 'a marker of ' , widthInBytes asString
			, ' bytes does not fit in a key size of ' , keySizeInBytes asString ].
	(anInteger between: 0 and: (256 raisedTo: widthInBytes) - 1) ifFalse: [
		^ self error: 'marker ' , anInteger asString , ' does not fit in '
			, widthInBytes asString , ' bytes' ].
	prefix := anInteger.
	width := widthInBytes.
	keySize := keySizeInBytes
]

{ #category : #accessing }
SoilPrefixRange >> width [
	"how many bytes my marker occupies in front of every key. Fixed when the index is
	created, and 0 means there is no namespace at all"

	^ width
]
