Class {
	#name : #SoilDerivedKeyLayoutTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilDerivedKeyLayoutTest >> keyOf: aValue in: aLayout [
	"the number the index orders by"
	^ (aLayout keyFor: aValue primaryKey: #[0 0 0 0 0 0 0 1]) asIndexKeyOfSize: aLayout keySize
]

{ #category : #helpers }
SoilDerivedKeyLayoutTest >> nonUnique [
	^ SoilDerivedKeyLayout keySize: 16 unique: false primaryKeySize: 8
]

{ #category : #helpers }
SoilDerivedKeyLayoutTest >> unique [
	^ SoilDerivedKeyLayout keySize: 8 unique: true primaryKeySize: 8
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testAKeyFillsTheWholeKeySize [
	self assert: (self nonUnique keyFor: 'a' primaryKey: #[0 0 0 0 0 0 0 2]) size equals: 16.
	self assert: (self unique keyFor: 'a' primaryKey: #[0 0 0 0 0 0 0 2]) size equals: 8
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testAttributeIsLeftAlignedAndThePrimaryKeyFollows [
	self
		assert: (self nonUnique keyFor: 'ab' primaryKey: #[0 0 0 0 0 0 0 2])
		equals: #[97 98 0 0 0 0 0 0 0 0 0 0 0 0 0 2]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testByteArrayIsLeftAligned [
	self
		assert: (self unique keyFor: #[5 6] primaryKey: #[0 0 0 0 0 0 0 1])
		equals: #[5 6 0 0 0 0 0 0]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testIntegerIsRightAlignedBigEndian [
	self
		assert: (self unique keyFor: 258 primaryKey: #[0 0 0 0 0 0 0 1])
		equals: #[0 0 0 0 0 0 1 2]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testIntegersOrderNumerically [
	| layout |
	layout := self nonUnique.
	self assert: (self keyOf: 9 in: layout) < (self keyOf: 10 in: layout).
	self assert: (self keyOf: 255 in: layout) < (self keyOf: 256 in: layout).
	self assert: (self keyOf: 0 in: layout) < (self keyOf: 1 in: layout)
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfNilIsAnError [
	self should: [ self nonUnique keyFor: nil primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfABooleanIsAnError [
	self should: [ self nonUnique keyFor: true primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfADateIsAnError [
	self should: [ self nonUnique keyFor: Date today primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfAFloatIsAnError [
	self should: [ self nonUnique keyFor: 1.5 primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfANegativeNumberIsAnError [
	self should: [ self nonUnique keyFor: -1 primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfAWideStringIsAnError [
	self
		should: [ self nonUnique keyFor: (WideString with: (Character value: 8364)) primaryKey: #[0 0 0 0 0 0 0 1] ]
		raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfATooLongIntegerIsAnError [
	"the attribute part of a non-unique layout of key size 16 is 8 bytes"
	self should: [ self nonUnique keyFor: (256 raisedTo: 8) primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError.
	self shouldnt: [ self nonUnique keyFor: (256 raisedTo: 8) - 1 primaryKey: #[0 0 0 0 0 0 0 1] ] raise: Error
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfATooLongStringIsAnErrorAndIsNotCutOff [
	self should: [ self nonUnique keyFor: '123456789' primaryKey: #[0 0 0 0 0 0 0 1] ] raise: SoilUnsupportedError.
	self shouldnt: [ self nonUnique keyFor: '12345678' primaryKey: #[0 0 0 0 0 0 0 1] ] raise: Error
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testNonUniqueNeedsRoomForAnAttribute [
	self should: [ SoilDerivedKeyLayout keySize: 8 unique: false primaryKeySize: 8 ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testRangeOfNonUniqueSpansPrimaryKeyZeroToAllOnes [
	| range |
	range := self nonUnique rangeFor: 'ab'.
	self assert: range firstKey equals: #[97 98 0 0 0 0 0 0 0 0 0 0 0 0 0 0].
	self assert: range lastKey equals: #[97 98 0 0 0 0 0 0 255 255 255 255 255 255 255 255]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testRangeIncludesKeysOfTheSameValueOnly [
	| layout range |
	layout := self nonUnique.
	range := layout rangeFor: 'ab'.
	self assert: (range includesKey: (self keyOf: 'ab' in: layout)).
	self deny: (range includesKey: (self keyOf: 'aa' in: layout)).
	self deny: (range includesKey: (self keyOf: 'abc' in: layout)).
	self deny: (range includesKey: (self keyOf: 'b' in: layout))
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testRangeOfUniqueIsTheSingleKey [
	| range |
	range := self unique rangeFor: 7.
	self assert: range firstKey equals: #[0 0 0 0 0 0 0 7].
	self assert: range lastKey equals: #[0 0 0 0 0 0 0 7]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testStringsOrderByTheirBytes [
	"not by their length, as an ordinary index key would"
	| layout |
	layout := self nonUnique.
	self assert: (self keyOf: 'aa' in: layout) < (self keyOf: 'b' in: layout).
	self assert: (self keyOf: 'a' in: layout) < (self keyOf: 'aa' in: layout)
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testSymbolIsEncodedLikeAString [
	self
		assert: (self unique keyFor: #ab primaryKey: #[0 0 0 0 0 0 0 1])
		equals: (self unique keyFor: 'ab' primaryKey: #[0 0 0 0 0 0 0 1])
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testAttributeSizeIsKeySizeMinusPrimaryKeySize [
	self
		assert: (SoilDerivedKeyLayout keySize: 16 unique: false primaryKeySize: 10) attributeSize
		equals: 6.
	self
		assert: (SoilDerivedKeyLayout keySize: 16 unique: true primaryKeySize: 10) attributeSize
		equals: 16
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testPrimaryKeyOfTheWrongSizeIsAnError [
	self
		should: [ self nonUnique keyFor: 'a' primaryKey: #[1 2 3] ]
		raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testNoRoomForAnAttributeBeforeThePrimaryKeyIsAnError [
	self
		should: [ SoilDerivedKeyLayout keySize: 10 unique: false primaryKeySize: 10 ]
		raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testEqualAttributesOrderByPrimaryKey [
	| layout low high |
	layout := self nonUnique.
	low := (layout keyFor: 'x' primaryKey: #[0 0 0 0 0 0 0 1]) asIndexKeyOfSize: 16.
	high := (layout keyFor: 'x' primaryKey: #[0 0 0 0 0 0 1 0]) asIndexKeyOfSize: 16.
	self assert: low < high
]
