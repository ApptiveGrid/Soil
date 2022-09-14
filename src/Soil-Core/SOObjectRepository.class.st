Class {
	#name : #SOObjectRepository,
	#superclass : #Object,
	#instVars : [
		'soil',
		'segments'
	],
	#category : #'Soil-Core'
}

{ #category : #adding }
SOObjectRepository >> addNewSegment [
	| currentSegments index |
	currentSegments := self segments.
	index := currentSegments size + 1.
	segments := Array new: index.
	^ segments 
		at: index 
		put: (SOObjectSegment new 
			id: index;
			objectRepository: self)

]

{ #category : #accessing }
SOObjectRepository >> at: objectid [ 
	| segment |
	segment := self segmentAt: objectid segment.
	^ segment at: objectid index
]

{ #category : #accessing }
SOObjectRepository >> at: objectId put: bytes [ 
	| position segment |
	segment := self segmentAt: objectId segment.
	segment at: objectId index putBytes: bytes	
]

{ #category : #initialization }
SOObjectRepository >> initializeFilesystem [
	(soil path / #segments) ensureCreateDirectory 
]

{ #category : #initialization }
SOObjectRepository >> loadSegments [
	| path b |
	path := soil path / #segments.
	path exists ifFalse: [ SOSoilNotInitialized signal: 'soil instance on ', path pathString, ' has not been initialized' ].
	^ path directories collect: [ :directory |
		SOObjectSegment new 
			id: directory basename asInteger;
			objectRepository: self  ]
	
]

{ #category : #accessing }
SOObjectRepository >> segmentAt: anInteger [ 
	^ self segments at: anInteger 
]

{ #category : #accessing }
SOObjectRepository >> segments [ 
	^ segments ifNil: [ 
		segments := self loadSegments ]
]

{ #category : #accessing }
SOObjectRepository >> soil [
	^ soil
]

{ #category : #accessing }
SOObjectRepository >> soil: aSoil [ 
	soil := aSoil 
]
