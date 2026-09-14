"
The properties a shared index rests on: a marker sits at the front of every key and
nowhere else, a key always fills the whole key size, and a scan that asks its range where
it ends stops at its own last entry instead of reading on into the next section.

The last one is the only one that needs a real index, and it is the one that would go
wrong in silence -- nothing about an index says that it is shared.
"
Class {
	#name : #SoilPrefixRangeTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilPrefixRangeTest >> indexWithKeysOfSize: anInteger [

	^ SoilSkipList new
		initializeHeaderPage;
		keySize: anInteger;
		valueSize: 8;
		maxLevel: 4;
		yourself
]

{ #category : #helpers }
SoilPrefixRangeTest >> put: aCollection underMarker: anInteger into: anIndex [

	| range |
	range := SoilPrefixRange prefix: anInteger width: 1 keySize: 4.
	aCollection withIndexDo: [ :value :position |
		anIndex
			at: (range keyWith: (position asByteArrayOfSize: 3))
			add: (value asByteArrayOfSize: 8) ]
]

{ #category : #helpers }
SoilPrefixRangeTest >> readAll: aRange from: anIndex [
	"what a reader on a shared index does: jump to the start of its own section, then on
	past each key it read, and stop when the range says the key is no longer its own.

	Past the last key of the index #nextKeyCloseTo: answers nil, so the loop ends there on
	its own and the range only has to answer for keys that do exist."

	| iterator read key found |
	iterator := anIndex newIterator.
	read := OrderedCollection new.
	key := aRange firstIndexKey.
	[ found := iterator nextKeyCloseTo: key.
	  found notNil and: [ aRange includesKey: found ] ] whileTrue: [
			read add: (iterator at: found) asInteger.
			key := found + 1 ].
	^ read asArray
]

{ #category : #tests }
SoilPrefixRangeTest >> testAKeyFillsTheWholeKeySizeWithThePaddingLast [
	"the property the whole scheme rests on. A shorter key is packed into a smaller number,
	which amounts to padding it on the left -- and that moves the marker out of the front"

	| range |
	range := SoilPrefixRange prefix: 3 width: 1 keySize: 6.
	self assert: (range keyWith: #[9 9]) equals: #[3 9 9 0 0 0]
]

{ #category : #tests }
SoilPrefixRangeTest >> testAKeyThatDoesNotFitBehindTheMarkerIsRefused [

	| range |
	range := SoilPrefixRange prefix: 3 width: 1 keySize: 4.
	self
		should: [ range keyWith: #[1 2 3 4] ]
		raise: Error
]

{ #category : #tests }
SoilPrefixRangeTest >> testAMarkerTooWideForItsWidthIsRefused [
	"a marker that does not fit would be truncated, and two sections would silently share
	one namespace"

	self
		should: [ SoilPrefixRange prefix: 256 width: 1 keySize: 8 ]
		raise: Error.
	self
		should: [ SoilPrefixRange prefix: 1 width: 9 keySize: 8 ]
		raise: Error
]

{ #category : #tests }
SoilPrefixRangeTest >> testAScanStopsAtTheEndOfItsOwnSection [
	"the reason the range exists: the index has no idea that it is shared, so the loop asks
	the range where its section ends. The third marker has no entries at all, which is the
	case that walks off the end of the index"

	| index |
	index := self indexWithKeysOfSize: 4.
	self put: #( 11 12 ) underMarker: 1 into: index.
	self put: #( 21 ) underMarker: 2 into: index.

	self
		assert: (self readAll: (SoilPrefixRange prefix: 1 width: 1 keySize: 4) from: index)
		equals: #( 11 12 ).
	self
		assert: (self readAll: (SoilPrefixRange prefix: 2 width: 1 keySize: 4) from: index)
		equals: #( 21 ).
	self
		assert: (self readAll: (SoilPrefixRange prefix: 3 width: 1 keySize: 4) from: index)
		equals: #(  )
]

{ #category : #tests }
SoilPrefixRangeTest >> testAWidthOfZeroLeavesTheIndexToOneSection [
	"then there is no namespace, and the structure pays no byte for it"

	| range |
	range := SoilPrefixRange prefix: 0 width: 0 keySize: 4.
	self assert: (range keyWith: #[1 2 3 4]) equals: #[1 2 3 4].
	self assert: range firstKey equals: #[0 0 0 0].
	self assert: range lastKey equals: #[255 255 255 255].
	self assert: (range includesKey: #[255 255 255 255])
]

{ #category : #tests }
SoilPrefixRangeTest >> testAWidthOfZeroTakesNoMarkerOtherThanZero [

	self
		should: [ SoilPrefixRange prefix: 1 width: 0 keySize: 4 ]
		raise: Error
]

{ #category : #tests }
SoilPrefixRangeTest >> testMembershipEndsWhereTheNextMarkerBegins [

	| range |
	range := SoilPrefixRange prefix: 1 width: 1 keySize: 4.
	self assert: (range includesKey: #[1 0 0 0]).
	self assert: (range includesKey: #[1 255 255 255]).
	self deny: (range includesKey: #[0 255 255 255]).
	self deny: (range includesKey: #[2 0 0 0])
]

{ #category : #tests }
SoilPrefixRangeTest >> testMembershipTakesTheIndexKeyAnIteratorHandsBack [
	"an association carries its key as the number the index compares in, not as bytes"

	| range |
	range := SoilPrefixRange prefix: 1 width: 1 keySize: 4.
	self assert: (range includesKey: (#[1 0 0 5] asIndexKeyOfSize: 4)).
	self deny: (range includesKey: (#[2 0 0 5] asIndexKeyOfSize: 4))
]

{ #category : #tests }
SoilPrefixRangeTest >> testTheBoundsSpanExactlyOneMarker [

	| range |
	range := SoilPrefixRange prefix: 1 width: 1 keySize: 4.
	self assert: range firstKey equals: #[1 0 0 0].
	self assert: range lastKey equals: #[1 255 255 255]
]

{ #category : #tests }
SoilPrefixRangeTest >> testTheMarkerCanBeReadBackOutOfAKey [
	"the two directions of the encoding are one pair, which is why they live in one place"

	| range key |
	range := SoilPrefixRange prefix: 258 width: 2 keySize: 8.
	key := range keyWith: #[7 7 7].
	self
		assert: (SoilPrefixRange prefixIn: key width: 2 keySize: 8)
		equals: 258.
	self
		assert: (SoilPrefixRange prefixIn: (key asIndexKeyOfSize: 8) width: 2 keySize: 8)
		equals: 258
]
