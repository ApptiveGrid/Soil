"
Makes the size in an index's header page what the index holds (SoilIndex>>recomputeSize). It is the one safe way for a size that drifted, and so the default of SoilIndexSizeDrift.
"
Class {
	#name : #SoilRecomputeIndexSize,
	#superclass : #SoilRepairAction,
	#instVars : [
		'segment',
		'indexId'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilRecomputeIndexSize class >> actionName [
	^ #recomputeIndexSize
]

{ #category : #'instance creation' }
SoilRecomputeIndexSize class >> newFromDictionary: aDictionary [
	^ self
		segment: (aDictionary at: #segment)
		indexId: (aDictionary at: #indexId)
]

{ #category : #'instance creation' }
SoilRecomputeIndexSize class >> segment: anInteger indexId: anIndexId [
	^ self new
		segment: anInteger indexId: anIndexId;
		yourself
]

{ #category : #visiting }
SoilRecomputeIndexSize >> acceptSoil: aSoilVisitor [
	^ aSoilVisitor visitRecomputeIndexSize: self
]

{ #category : #accessing }
SoilRecomputeIndexSize >> asDictionary [
	^ super asDictionary
		at: #segment put: segment;
		at: #indexId put: indexId;
		yourself
]

{ #category : #accessing }
SoilRecomputeIndexSize >> description [
	^ 'recompute the size of index ', indexId printString, ' of segment ', segment printString, ' from what it holds'
]

{ #category : #accessing }
SoilRecomputeIndexSize >> indexId [
	^ indexId
]

{ #category : #accessing }
SoilRecomputeIndexSize >> indexIn: aSoil [
	^ (aSoil objectRepository segmentAt: segment) indexAt: indexId
]

{ #category : #testing }
SoilRecomputeIndexSize >> isDefault [
	^ true
]

{ #category : #accessing }
SoilRecomputeIndexSize >> segment [
	^ segment
]

{ #category : #initialization }
SoilRecomputeIndexSize >> segment: anInteger indexId: anIndexId [
	segment := anInteger.
	indexId := anIndexId
]
