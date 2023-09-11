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
SoilObjectRepository >> addNewSegment [
	^ self addNewSegment: (SoilObjectSegment new 
			id: self segments size + 1;
			objectRepository: self;
			yourself)
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

{ #category : #accessing }
SoilObjectRepository >> cacheSegmentAt: index upTo: limit [ 
	(index = 0) 
		ifTrue: [ metaSegment := metaSegment asCachedSegment weight: limit ]
		ifFalse: [  
			segments 	
				at: index 
				put: ((segments at: index) asCachedSegment weight: limit) ]
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

{ #category : #accessing }
SoilObjectRepository >> heapPositionOf: anObjectId [ 
	^ (self segmentAt: anObjectId segment)
		heapPositionAt: anObjectId index  
]

{ #category : #initialization }
SoilObjectRepository >> initializeFilesystem [
	| firstSegment |
	(soil path / #segments) ensureCreateDirectory.
	segments := OrderedCollection new.
	metaSegment := self newMetaSegment
		initializeFilesystem;
		"initialize last index with 2 which is the meta description"
		lastObjectIndex: 2;
		yourself.
	firstSegment := self newSegment 
		id: 1;
		yourself.
	self addNewSegment: firstSegment.
	"initialize last index with 1 which is the placeholder for the 
	root object"
	firstSegment lastObjectIndex: 1.
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
				metaSegment := self newMetaSegment
					open;
					yourself ]
			ifFalse: [ 
				segments 
					at: segmentId 
					put: (self newSegment 
						id: segmentId;
						open;
						yourself) ] ].
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
	^ SoilObjectSegment new 
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

{ #category : #enumerating }
SoilObjectRepository >> segmentsDo: aBlock [ 
	aBlock value: metaSegment.
	segments do: aBlock
]

{ #category : #accessing }
SoilObjectRepository >> soil [
	^ soil
]

{ #category : #accessing }
SoilObjectRepository >> soil: aSoil [ 
	soil := aSoil 
]
