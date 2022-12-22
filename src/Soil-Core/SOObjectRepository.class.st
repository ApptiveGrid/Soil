Class {
	#name : #SOObjectRepository,
	#superclass : #Object,
	#instVars : [
		'soil',
		'segments'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SOObjectRepository >> addNewSegment [
	| newSegment |
	newSegment := (SOObjectSegment new 
			id: self segments size + 1;
			objectRepository: self) 
				initializeFilesystem .
	segments := self segments copyWith: newSegment.
	^ newSegment
]

{ #category : #accessing }
SOObjectRepository >> allVersionsOf: aSOObjectId [ 
	| segment |
	segment := self segmentAt: aSOObjectId segment.
	^ segment allVersionsOf: aSOObjectId
]

{ #category : #accessing }
SOObjectRepository >> at: objectid [ 
	| segment |
	segment := self segmentAt: objectid segment.
	^ (segment at: objectid index)
		objectId: objectid;
		yourself
]

{ #category : #accessing }
SOObjectRepository >> at: objectId put: bytes [ 
	| segment |
	(objectId index = 0) ifTrue: [ self halt ].
	segment := self segmentAt: objectId segment.
	segment at: objectId index putBytes: bytes
]

{ #category : #'initialize-release' }
SOObjectRepository >> close [
	segments do: #close
]

{ #category : #accessing }
SOObjectRepository >> defaultSegment [
	^ self segments first
]

{ #category : #accessing }
SOObjectRepository >> firstSegment [
	^ segments first
]

{ #category : #initialization }
SOObjectRepository >> initializeFilesystem [
	(soil path / #segments) ensureCreateDirectory
]

{ #category : #initialization }
SOObjectRepository >> loadSegments [
	| path |
	path := soil path / #segments.
	path exists ifFalse: [ SOSoilNotInitialized signal: 'soil instance on ', path pathString, ' has not been initialized' ].
	^ path directories collect: [ :directory |
		SOObjectSegment new 
			id: directory basename asInteger;
			objectRepository: self  ]
]

{ #category : #accessing }
SOObjectRepository >> newObjectId [
	^ self defaultSegment newObjectId
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
