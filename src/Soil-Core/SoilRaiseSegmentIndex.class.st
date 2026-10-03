"
Raises the last object index a segment has handed out to an index that ids already point to (SoilObjectSegment>>updateLastObjectIndex:), which never lowers it. The ids between are not handed out again, so what refers to them is not taken for new objects. It is the repair of SoilObjectIdOutsideSegment for an id beyond the segment's last index.

It is not a default: it makes the segment trust the id it names, and the next object is stored after it. For an id that is far off - a damaged pointer rather than a counter that was not written - that is not what is wanted, so a person looks at the number first.
"
Class {
	#name : #SoilRaiseSegmentIndex,
	#superclass : #SoilRepairAction,
	#instVars : [
		'segment',
		'index'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilRaiseSegmentIndex class >> actionName [
	^ #raiseSegmentIndex
]

{ #category : #'instance creation' }
SoilRaiseSegmentIndex class >> newFromDictionary: aDictionary [
	^ self
		segment: (aDictionary at: #segment)
		index: (aDictionary at: #index)
]

{ #category : #'instance creation' }
SoilRaiseSegmentIndex class >> segment: anInteger index: anIndex [
	^ self new
		segment: anInteger index: anIndex;
		yourself
]

{ #category : #visiting }
SoilRaiseSegmentIndex >> acceptSoil: aSoilVisitor [
	^ aSoilVisitor visitRaiseSegmentIndex: self
]

{ #category : #accessing }
SoilRaiseSegmentIndex >> asDictionary [
	^ super asDictionary
		at: #segment put: segment;
		at: #index put: index;
		yourself
]

{ #category : #accessing }
SoilRaiseSegmentIndex >> description [
	^ 'raise the last object index of segment ', segment printString, ' to ', index printString
]

{ #category : #accessing }
SoilRaiseSegmentIndex >> index [
	^ index
]

{ #category : #accessing }
SoilRaiseSegmentIndex >> segment [
	^ segment
]

{ #category : #initialization }
SoilRaiseSegmentIndex >> segment: anInteger index: anIndex [
	segment := anInteger.
	index := anIndex
]
