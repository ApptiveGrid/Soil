Class {
	#name : #SoilKeyEncodingTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilKeyEncodingTest >> assertComparisonAgreesFor: someValues width: aWidth [
	someValues do: [ :each |
		someValues do: [ :other |
			| bytes otherBytes expected |
			bytes := self encoding encode: each width: aWidth.
			otherBytes := self encoding encode: other width: aWidth.
			expected := bytes = otherBytes
				ifTrue: [ 0 ]
				ifFalse: [ (self isBytes: bytes lessThan: otherBytes) ifTrue: [ -1 ] ifFalse: [ 1 ] ].
			self assert: (self encoding compare: each with: other) equals: expected ] ]
]

{ #category : #helpers }
SoilKeyEncodingTest >> encoding [
	^ SoilKeyEncoding standard
]

{ #category : #helpers }
SoilKeyEncodingTest >> isBytes: someBytes lessThan: otherBytes [
	1 to: someBytes size do: [ :each |
		(someBytes at: each) = (otherBytes at: each) ifFalse: [ ^ (someBytes at: each) < (otherBytes at: each) ] ].
	^ false
]

{ #category : #tests }
SoilKeyEncodingTest >> testCompareAgreesWithTheEncodedBytesAtAWidth [
	"the order without a width is the order of the bytes with one, for strings, byte arrays and numbers"
	| values |
	values := { 'a'. 'aa'. 'b'. 'B'. 'ab'. ''. 'Zed' }.
	self assertComparisonAgreesFor: values width: 8.
	self assertComparisonAgreesFor: { #[1]. #[1 2]. #[0 9]. #[255]. #[] } width: 8.
	self assertComparisonAgreesFor: { 0. 1. 255. 256. 70000. 5 } width: 8
]

{ #category : #tests }
SoilKeyEncodingTest >> testEncodesNumbersRightAligned [
	self assert: (self encoding encode: 258 width: 4) equals: #[0 0 1 2].
	self assert: (self encoding encode: 0 width: 2) equals: #[0 0]
]

{ #category : #tests }
SoilKeyEncodingTest >> testEncodesStringsAndByteArraysLeftAligned [
	self assert: (self encoding encode: 'ab' width: 4) equals: #[97 98 0 0].
	self assert: (self encoding encode: #ab width: 3) equals: #[97 98 0].
	self assert: (self encoding encode: #[7] width: 2) equals: #[7 0]
]

{ #category : #tests }
SoilKeyEncodingTest >> testNumbersOrderNumerically [
	self assert: (self encoding compare: 9 with: 10) equals: -1.
	self assert: (self encoding compare: 256 with: 255) equals: 1
]

{ #category : #tests }
SoilKeyEncodingTest >> testRefusesAValueThatDoesNotFitTheWidthAndDoesNotCutIt [
	self should: [ self encoding encode: '12345' width: 4 ] raise: SoilUnsupportedError.
	self should: [ self encoding encode: 256 width: 1 ] raise: SoilUnsupportedError.
	self assert: (self encoding encode: 255 width: 1) equals: #[255]
]

{ #category : #tests }
SoilKeyEncodingTest >> testRefusesWhatCannotBeIndexed [
	{ nil. -1. 1.5. true. Date today. (WideString with: (Character value: 8364)) } do: [ :each |
		self should: [ self encoding encode: each width: 8 ] raise: SoilUnsupportedError.
		self should: [ self encoding compare: each with: 'a' ] raise: SoilUnsupportedError ]
]

{ #category : #tests }
SoilKeyEncodingTest >> testStartingWithComparesTheFrontOfTheEncodedBytes [
	self assert: (self encoding isValue: 'Roeder' startingWith: 'Roe').
	self deny: (self encoding isValue: 'Ro' startingWith: 'Roe').
	self assert: (self encoding isValue: #[1 2 3] startingWith: #[1 2]).
	self assert: (self encoding isValue: 'ab' startingWith: '').
	self should: [ self encoding isValue: 5 startingWith: 'a' ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilKeyEncodingTest >> testStringsOrderByBytesAndNotByLength [
	self assert: (self encoding compare: 'aa' with: 'b') equals: -1.
	self assert: (self encoding compare: 'B' with: 'a') equals: -1.
	self assert: (self encoding compare: 'a' with: 'a') equals: 0
]
