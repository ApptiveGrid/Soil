Class {
	#name : #SoilDerivedKeyLayoutTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilDerivedKeyLayoutTest >> keyOf: aValue in: aLayout [
	"the number the index orders by"
	^ (aLayout keyFor: aValue objectId: (SoilObjectId segment: 1 index: 1)) asIndexKeyOfSize: aLayout keySize
]

{ #category : #helpers }
SoilDerivedKeyLayoutTest >> nonUnique [
	^ SoilDerivedKeyLayout keySize: 16 unique: false
]

{ #category : #helpers }
SoilDerivedKeyLayoutTest >> unique [
	^ SoilDerivedKeyLayout keySize: 8 unique: true
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testAKeyFillsTheWholeKeySize [
	self assert: (self nonUnique keyFor: 'a' objectId: (SoilObjectId segment: 1 index: 2)) size equals: 16.
	self assert: (self unique keyFor: 'a' objectId: (SoilObjectId segment: 1 index: 2)) size equals: 8
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testAttributeIsLeftAlignedAndTheObjectIdFollows [
	self
		assert: (self nonUnique keyFor: 'ab' objectId: (SoilObjectId segment: 1 index: 2))
		equals: #[97 98 0 0 0 0 0 0 0 1 0 0 0 0 0 2]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testByteArrayIsLeftAligned [
	self
		assert: (self unique keyFor: #[5 6] objectId: nil)
		equals: #[5 6 0 0 0 0 0 0]
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testIntegerIsRightAlignedBigEndian [
	self
		assert: (self unique keyFor: 258 objectId: nil)
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
	self should: [ self nonUnique keyFor: nil objectId: nil ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfABooleanIsAnError [
	self should: [ self nonUnique keyFor: true objectId: nil ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfADateIsAnError [
	self should: [ self nonUnique keyFor: Date today objectId: nil ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfAFloatIsAnError [
	self should: [ self nonUnique keyFor: 1.5 objectId: nil ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfANegativeNumberIsAnError [
	self should: [ self nonUnique keyFor: -1 objectId: nil ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfAWideStringIsAnError [
	self
		should: [ self nonUnique keyFor: (WideString with: (Character value: 8364)) objectId: nil ]
		raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfATooLongIntegerIsAnError [
	"the attribute part of a non-unique layout of key size 16 is 8 bytes"
	self should: [ self nonUnique keyFor: (256 raisedTo: 8) objectId: nil ] raise: SoilUnsupportedError.
	self shouldnt: [ self nonUnique keyFor: (256 raisedTo: 8) - 1 objectId: (SoilObjectId segment: 1 index: 1) ] raise: Error
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testKeyOfATooLongStringIsAnErrorAndIsNotCutOff [
	self should: [ self nonUnique keyFor: '123456789' objectId: nil ] raise: SoilUnsupportedError.
	self shouldnt: [ self nonUnique keyFor: '12345678' objectId: (SoilObjectId segment: 1 index: 1) ] raise: Error
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testNonUniqueNeedsRoomForAnAttribute [
	self should: [ SoilDerivedKeyLayout keySize: 8 unique: false ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilDerivedKeyLayoutTest >> testRangeOfNonUniqueSpansObjectIdZeroToAllOnes [
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
		assert: (self unique keyFor: #ab objectId: nil)
		equals: (self unique keyFor: 'ab' objectId: nil)
]
