Class {
	#name : #SoilObjectRepository,
	#superclass : #Object,
	#instVars : [
		'soil',
		'metaSegment',
		'segments'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilObjectRepository >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitObjectRepository: self
]

{ #category : #adding }
SoilObjectRepository >> addFirstSegment [
	| segment |
	segment := SoilObjectSegment new id: 1.
	self addNewSegment: segment.
	"skip using index 1 because that is the root object"
	segment allocateNextIndex 
]

{ #category : #adding }
SoilObjectRepository >> addMetaSegment [
	^ metaSegment := (SoilMetaSegment new id: 0) 
		objectRepository: self;
		initializeFilesystem;
		"skip first index as this is the meta behavior description"
		allocateNextIndex;
		yourself
]

{ #category : #adding }
SoilObjectRepository >> addNewSegment [
	^ self addNewSegment: (SoilObjectSegment new 
			id: self segments size + 1;
			objectRepository: self)
]

{ #category : #adding }
SoilObjectRepository >> addNewSegment: aSegment [
	aSegment 
		objectRepository: self;
		initializeFilesystem.
	segments add: aSegment.
	^ aSegment 
]

{ #category : #accessing }
SoilObjectRepository >> allSegments [ 
	^ segments copyWithFirst: metaSegment 
]

{ #category : #accessing }
SoilObjectRepository >> allVersionsOf: aSOObjectId [ 
	| segment |
	segment := self segmentAt: aSOObjectId segment.
	^ segment allVersionsAt: aSOObjectId index
]

{ #category : #accessing }
SoilObjectRepository >> at: objectid [ 
	| segment |
	segment := self segmentAt: objectid segment.
	^ (segment at: objectid index)
		objectId: objectid;
		yourself
]

{ #category : #accessing }
SoilObjectRepository >> at: objectId put: bytes [ 
	| segment |
	(objectId index = 0) ifTrue: [ Error signal: 'objectId is not initialized when trying to store' ].
	segment := self segmentAt: objectId segment.
	^ segment at: objectId index putBytes: bytes	
]

{ #category : #accessing }
SoilObjectRepository >> at: objectid version: version [ 
	| segment |
	segment := self segmentAt: objectid segment.
	^ (segment at: objectid index version: version)
		ifNotNil: [ :record | record objectId: objectid ]
]

{ #category : #'opening/closing' }
SoilObjectRepository >> close [
	metaSegment close.
	segments do: #close
]

{ #category : #accessing }
SoilObjectRepository >> firstSegment [
	^ segments first
]

{ #category : #initialization }
SoilObjectRepository >> initializeFilesystem [
	(soil path / #segments) ensureCreateDirectory.
	segments := OrderedCollection new.
	self addMetaSegment.
	self addFirstSegment
]

{ #category : #initialization }
SoilObjectRepository >> loadSegments [
	| path directories |
	path := soil path / #segments.
	path exists ifFalse: [ SoilSoilNotInitialized signal: 'soil instance on ', path pathString, ' has not been initialized' ].
	directories := path directories.
	segments := Array new: directories size - 1.
	directories do: [ :directory | | segmentId segment |
		segmentId := directory basename asInteger.
		segment := SoilObjectSegment new 
			id: segmentId;
			objectRepository: self.
		segmentId isZero 
			ifTrue: [ 
				metaSegment := self newMetaSegment ]
			ifFalse: [ 
				segments 
					at: segmentId 
					put: (self newSegment 
						id: segmentId) ] ].
	^ segments
	
]

{ #category : #accessing }
SoilObjectRepository >> lockObjectId: aSOObjectId for: lockContext [
	^ (self segmentAt: aSOObjectId segment)
		lockObjectId: aSOObjectId for: lockContext
]

{ #category : #accessing }
SoilObjectRepository >> metaSegment [
	^ metaSegment 
]

{ #category : #accessing }
SoilObjectRepository >> newMetaObjectId [
	^ self metaSegment newObjectId
]

{ #category : #'instance creation' }
SoilObjectRepository >> newMetaSegment [ 
	^ SoilMetaSegment new 
		objectRepository: self;
		id: 0;
		yourself
]

{ #category : #accessing }
SoilObjectRepository >> newObjectId [
	^ self firstSegment newObjectId
]

{ #category : #'instance creation' }
SoilObjectRepository >> newSegment [ 
	^ SoilObjectSegment new 
		objectRepository: self;
		yourself
]

{ #category : #accessing }
SoilObjectRepository >> positionOf: anObjectId [ 
	^ (self segmentAt: anObjectId segment)
		indexFile positionAt: anObjectId index  
]

{ #category : #accessing }
SoilObjectRepository >> segmentAt: anInteger [ 
	^ anInteger isZero 
		ifTrue: [ metaSegment ]
		ifFalse: [ self segments at: anInteger ]
]

{ #category : #accessing }
SoilObjectRepository >> segments [ 
	^ segments ifNil: [ 
		segments := self loadSegments ]
]

{ #category : #accessing }
SoilObjectRepository >> soil [
	^ soil
]

{ #category : #accessing }
SoilObjectRepository >> soil: aSoil [ 
	soil := aSoil 
]
