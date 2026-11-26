"
I remember which objects a walk through the graph has met: one bit for each object index of a segment, instead of the object id itself in a Set. A hundred million objects take 12.5 MB.

A segment has as many bits as its last object index asks for, fixed when I am made, see #lastObjectIndexes:. The bits of the segments sit in an Array at the segment id plus one, as many slots as the highest segment id asks for. A slot of a segment I was not given holds an empty ByteArray, and so does a position past the end of the Array, so that an id of such a segment has no room, like an index past the last object index of its segment.

An id that has no room is kept in a Set of its own, outOfBounds, as the walk kept every id before. That is a reference gone wrong, or an object made after I was, and the walk goes on with them as it did.

The object id 0:0, the marker of a removed value, takes the first bit like any other id. It is met once.
"
Class {
	#name : #SoilObjectIdBitmap,
	#superclass : #Object,
	#instVars : [
		'bitsBySegment',
		'outOfBounds'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #'instance creation' }
SoilObjectIdBitmap class >> forRepository: aSoilObjectRepository [
	"with the room each segment has now, the meta segment included. The last object index
	is read from the index file each time it is asked for, so once here for each segment
	and not for each id"
	| lastObjectIndexes |
	lastObjectIndexes := Dictionary new.
	{ aSoilObjectRepository metaSegment }, aSoilObjectRepository segments do: [ :segment |
		lastObjectIndexes at: segment id put: segment lastObjectIndex ].
	^ self lastObjectIndexes: lastObjectIndexes
]

{ #category : #'instance creation' }
SoilObjectIdBitmap class >> lastObjectIndexes: aDictionary [
	"segment id -> the highest object index to have a bit"
	^ self new initializeWith: aDictionary
]

{ #category : #adding }
SoilObjectIdBitmap >> add: anObjectId [
	| bits index byteIndex |
	bits := bitsBySegment at: anObjectId segment + 1 ifAbsent: [ #[] ].
	index := anObjectId index.
	byteIndex := (index bitShift: -3) + 1.
	byteIndex <= bits size ifFalse: [
		outOfBounds add: anObjectId.
		^ anObjectId ].
	bits
		at: byteIndex
		put: ((bits at: byteIndex) bitOr: (1 bitShift: (index bitAnd: 7))).
	^ anObjectId
]

{ #category : #testing }
SoilObjectIdBitmap >> includes: anObjectId [
	| bits index byteIndex |
	bits := bitsBySegment at: anObjectId segment + 1 ifAbsent: [ #[] ].
	index := anObjectId index.
	byteIndex := (index bitShift: -3) + 1.
	byteIndex <= bits size ifFalse: [ ^ outOfBounds includes: anObjectId ].
	^ ((bits at: byteIndex) bitAnd: (1 bitShift: (index bitAnd: 7))) ~= 0
]

{ #category : #initialization }
SoilObjectIdBitmap >> initializeWith: aDictionary [
	bitsBySegment := Array
		new: (aDictionary keys inject: 0 into: [ :highest :each | highest max: each ]) + 1
		withAll: #[].
	aDictionary keysAndValuesDo: [ :segmentId :lastObjectIndex |
		bitsBySegment
			at: segmentId + 1
			put: (ByteArray new: lastObjectIndex // 8 + 1) ].
	outOfBounds := Set new
]
