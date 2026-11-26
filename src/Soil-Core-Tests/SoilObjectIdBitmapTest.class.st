Class {
	#name : #SoilObjectIdBitmapTest,
	#superclass : #TestCase,
	#instVars : [
		'bitmap'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #helpers }
SoilObjectIdBitmapTest >> id: aSegmentId index: anInteger [
	^ SoilObjectId segment: aSegmentId index: anInteger
]

{ #category : #running }
SoilObjectIdBitmapTest >> setUp [
	super setUp.
	"the meta segment 0 with 10 objects, segments 1 and 2 with 100"
	bitmap := SoilObjectIdBitmap lastObjectIndexes: { 0 -> 10. 1 -> 100. 2 -> 100 } asDictionary
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testAddedIdIsIncluded [
	bitmap add: (self id: 1 index: 5).
	self assert: (bitmap includes: (self id: 1 index: 5))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testAddingTwiceChangesNothing [
	bitmap add: (self id: 1 index: 5).
	bitmap add: (self id: 1 index: 5).
	self assert: (bitmap includes: (self id: 1 index: 5)).
	self deny: (bitmap includes: (self id: 1 index: 6))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testFirstAndLastIndexOfASegment [
	bitmap add: (self id: 2 index: 1).
	bitmap add: (self id: 2 index: 100).
	self assert: (bitmap includes: (self id: 2 index: 1)).
	self assert: (bitmap includes: (self id: 2 index: 100)).
	self deny: (bitmap includes: (self id: 2 index: 2)).
	self deny: (bitmap includes: (self id: 2 index: 99))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testIdNotAddedIsNotIncluded [
	"the neighbours of the bit, and the bit at the same place in the next byte"
	bitmap add: (self id: 1 index: 5).
	self deny: (bitmap includes: (self id: 1 index: 4)).
	self deny: (bitmap includes: (self id: 1 index: 6)).
	self deny: (bitmap includes: (self id: 1 index: 13)).
	self deny: (bitmap includes: (self id: 1 index: 100))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testIdOfASegmentBetweenKnownSegmentsIsKept [
	"segment ids are ids and not positions: a removed segment leaves its id vacant, and
	the segments I was given can be fewer than the highest id"
	| gap |
	gap := SoilObjectIdBitmap lastObjectIndexes: { 0 -> 10. 3 -> 100 } asDictionary.
	gap add: (self id: 2 index: 5).
	gap add: (self id: 3 index: 5).
	self assert: (gap includes: (self id: 2 index: 5)).
	self assert: (gap includes: (self id: 3 index: 5)).
	self deny: (gap includes: (self id: 2 index: 6)).
	self deny: (gap includes: (self id: 3 index: 6))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testIdOfASegmentThatIsNotThereIsKept [
	"no room for it, it goes where an id with no room goes. Segment 65535 is the highest
	a segment id can be"
	bitmap add: (self id: 7 index: 3).
	bitmap add: (self id: 65535 index: 2).
	self assert: (bitmap includes: (self id: 7 index: 3)).
	self assert: (bitmap includes: (self id: 65535 index: 2)).
	self deny: (bitmap includes: (self id: 7 index: 4)).
	self deny: (bitmap includes: (self id: 65535 index: 3))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testIdPastTheLastObjectIndexIsKept [
	"not in a bit but not lost, and found by what it is and not by which object it is"
	bitmap add: (self id: 1 index: 100000).
	self assert: (bitmap includes: (self id: 1 index: 100000)).
	self deny: (bitmap includes: (self id: 1 index: 100001)).
	self deny: (bitmap includes: (self id: 2 index: 100000))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testIdWithIndexZeroTakesTheFirstBit [
	"0:0 is the marker of a removed value; met once, it is there"
	self deny: (bitmap includes: (self id: 0 index: 0)).
	bitmap add: (self id: 0 index: 0).
	self assert: (bitmap includes: (self id: 0 index: 0)).
	self deny: (bitmap includes: (self id: 0 index: 1))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testNeighboursInOneByteDoNotDisturbEachOther [
	"the indexes 8 to 15 are the eight bits of one byte"
	8 to: 15 do: [ :each | bitmap add: (self id: 1 index: each) ].
	8 to: 15 do: [ :each |
		self assert: (bitmap includes: (self id: 1 index: each)) ].
	self deny: (bitmap includes: (self id: 1 index: 7)).
	self deny: (bitmap includes: (self id: 1 index: 16))
]

{ #category : #tests }
SoilObjectIdBitmapTest >> testSegmentsAreKeptApart [
	bitmap add: (self id: 1 index: 7).
	self deny: (bitmap includes: (self id: 2 index: 7)).
	self deny: (bitmap includes: (self id: 0 index: 7)).
	bitmap add: (self id: 0 index: 7).
	self assert: (bitmap includes: (self id: 0 index: 7)).
	self deny: (bitmap includes: (self id: 2 index: 7))
]
