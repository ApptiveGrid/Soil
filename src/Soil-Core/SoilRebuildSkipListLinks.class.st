"
Makes the links of a skip list again from the right pointers of its first level: the left pointers, the right and left pointers of every higher level, and the tail of every level in the header page. The order of the pages is that of the first level, and each page knows how many levels it has, so nothing is lost and nothing is guessed. It is offered only where the first level can be walked to its end (SoilBrokenPageLink>>rightChainIntact); where it cannot, there is no repair.

It is not a default: the repair of all takes what a finding names as the one safe way, and for a damaged index that is for a person to say.
"
Class {
	#name : #SoilRebuildSkipListLinks,
	#superclass : #SoilRepairAction,
	#instVars : [
		'segment',
		'indexId'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilRebuildSkipListLinks class >> actionName [
	^ #rebuildSkipListLinks
]

{ #category : #'instance creation' }
SoilRebuildSkipListLinks class >> newFromDictionary: aDictionary [
	^ self
		segment: (aDictionary at: #segment)
		indexId: (aDictionary at: #indexId)
]

{ #category : #'instance creation' }
SoilRebuildSkipListLinks class >> segment: anInteger indexId: anIndexId [
	^ self new
		segment: anInteger indexId: anIndexId;
		yourself
]

{ #category : #visiting }
SoilRebuildSkipListLinks >> acceptSoil: aSoilVisitor [
	^ aSoilVisitor visitRebuildSkipListLinks: self
]

{ #category : #accessing }
SoilRebuildSkipListLinks >> asDictionary [
	^ super asDictionary
		at: #segment put: segment;
		at: #indexId put: indexId;
		yourself
]

{ #category : #accessing }
SoilRebuildSkipListLinks >> description [
	^ 'make the links of index ', indexId printString, ' of segment ', segment printString, ' again from the right pointers of its first level'
]

{ #category : #accessing }
SoilRebuildSkipListLinks >> indexId [
	^ indexId
]

{ #category : #accessing }
SoilRebuildSkipListLinks >> indexIn: aSoil [
	^ (aSoil objectRepository segmentAt: segment) indexAt: indexId
]

{ #category : #accessing }
SoilRebuildSkipListLinks >> segment [
	^ segment
]

{ #category : #initialization }
SoilRebuildSkipListLinks >> segment: anInteger indexId: anIndexId [
	segment := anInteger.
	indexId := anIndexId
]
