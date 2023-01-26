Class {
	#name : #SOObjectRepository,
	#superclass : #Object,
	#instVars : [
		'soil',
		'metaSegment',
		'segments'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SOObjectRepository >> addFirstSegment [
	| segment |
	segment := SOObjectSegment new id: 1.
	self addNewSegment: segment.
	"skip using index 1 because that is the root object"
	segment allocateNextIndex 
]

{ #category : #adding }
SOObjectRepository >> addMetaSegment [
	^ metaSegment := (SOMetaSegment new id: 0) 
		objectRepository: self;
		initializeFilesystem;
		"skip first index as this is the meta behavior description"
		allocateNextIndex;
		yourself
]

{ #category : #adding }
SOObjectRepository >> addNewSegment [
	^ self addNewSegment: (SOObjectSegment new 
			id: self segments size + 1;
			objectRepository: self)
]

{ #category : #adding }
SOObjectRepository >> addNewSegment: aSegment [
	aSegment 
		objectRepository: self;
		initializeFilesystem.
	segments add: aSegment.
	^ aSegment 
]

{ #category : #'as yet unclassified' }
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

{ #category : #accessing }
SOObjectRepository >> at: objectid version: version [ 
	| segment |
	segment := self segmentAt: objectid segment.
	^ (segment at: objectid index version: version)
		objectId: objectid;
		yourself
]

{ #category : #'initialize-release' }
SOObjectRepository >> close [
	segments do: #close
]

{ #category : #accessing }
SOObjectRepository >> firstSegment [
	^ segments first
]

{ #category : #initialization }
SOObjectRepository >> initializeFilesystem [
	(soil path / #segments) ensureCreateDirectory.
	segments := OrderedCollection new.
	self addMetaSegment.
	self addFirstSegment
]

{ #category : #initialization }
SOObjectRepository >> loadSegments [
	| path directories |
	path := soil path / #segments.
	path exists ifFalse: [ SOSoilNotInitialized signal: 'soil instance on ', path pathString, ' has not been initialized' ].
	directories := path directories.
	segments := Array new: directories size - 1.
	directories do: [ :directory | | segmentId segment |
		segmentId := directory basename asInteger.
		segment := SOObjectSegment new 
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

{ #category : #'as yet unclassified' }
SOObjectRepository >> lockObjectId: aSOObjectId for: lockContext [
	^ (self segmentAt: aSOObjectId segment)
		lockObjectId: aSOObjectId for: lockContext
]

{ #category : #accessing }
SOObjectRepository >> metaAt: index [ 
	^ self metaSegment at: index
]

{ #category : #accessing }
SOObjectRepository >> metaSegment [
	^ metaSegment 
]

{ #category : #accessing }
SOObjectRepository >> newMetaObjectId [
	^ self metaSegment newObjectId
]

{ #category : #'instance creation' }
SOObjectRepository >> newMetaSegment [ 
	^ SOMetaSegment new 
		objectRepository: self;
		id: 0;
		yourself
]

{ #category : #accessing }
SOObjectRepository >> newObjectId [
	^ self firstSegment newObjectId
]

{ #category : #'instance creation' }
SOObjectRepository >> newSegment [ 
	^ SOObjectSegment new 
		objectRepository: self;
		yourself
]

{ #category : #'as yet unclassified' }
SOObjectRepository >> positionOf: anObjectId [ 
	^ (self segmentAt: anObjectId segment)
		indexFile positionAt: anObjectId index  
]

{ #category : #accessing }
SOObjectRepository >> segmentAt: anInteger [ 
	^ anInteger isZero 
		ifTrue: [ metaSegment ]
		ifFalse: [ self segments at: anInteger ]
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
