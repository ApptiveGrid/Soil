Class {
	#name : #SoilObjectRepository,
	#superclass : #Object,
	#instVars : [
		'soil',
		'path',
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
	"once per segment in a database's life - today only the first one, from
	#initializeFilesystem. Cheap to say, and the kind of thing one wants dated"
	soil emit: 'segment ', aSegment id printString, ' created'.
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
SoilObjectRepository >> at: objectId putBytes: bytes [ 
	| segment position |
	(objectId index == 0) ifTrue: [ Error signal: 'objectId is not initialized when trying to store' ].
	segment := self segmentAt: objectId segment.
	position := segment at: objectId index putBytes: bytes.
	soil notificationHandler recordWritten: objectId.
	^ position
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
	(index == 0) 
		ifTrue: [ metaSegment := metaSegment asCachedSegment weight: limit ]
		ifFalse: [  
			segments 	
				at: index 
				put: ((segments at: index) asCachedSegment weight: limit) ]
]

{ #category : #setting }
SoilObjectRepository >> cacheSegmentAt: index using: aBlock [ 
	| segment |
	"exchange object segment with a LRU cached segment. The LRU cache
	can be setup within aBlock"
	(index == 0) 
		ifTrue: [ 
			metaSegment := metaSegment asCachedSegment.
			aBlock value: metaSegment ]
		ifFalse: [ 
			segment := (segments at: index) asCachedSegment.
			aBlock value: segment.
			segments 	
				at: index 
				put: segment ]
]

{ #category : #'opening/closing' }
SoilObjectRepository >> close [
	"closing what was never opened is nothing to do, not an error - #segments is
	loaded lazily, so it can still be nil here, and a failure while loading leaves
	it that way. Failing in #close would then bury the failure that caused it"

	Soil closeAll: ((OrderedCollection with: metaSegment)
		addAll: (segments ifNil: [ #() ]);
		yourself)
]

{ #category : #copying }
SoilObjectRepository >> copyVersionChain: aCollectionOfClusterVersions [
	"Delegate to the segment that owns the chain (all versions of an object share one
	objectId/segment). See SoilObjectSegment>>copyVersionChain:."
	aCollectionOfClusterVersions isEmpty ifTrue: [ ^ 0 ].
	^ (self segmentAt: aCollectionOfClusterVersions first objectId segment)
		copyVersionChain: aCollectionOfClusterVersions
]

{ #category : #copying }
SoilObjectRepository >> copyVersionChain: aCollectionOfClusterVersions upToReadVersion: aNumberOrNil [
	"Delegate the retention gate + copy to the owning segment. See
	SoilObjectSegment>>copyVersionChain:upToReadVersion: and keptVersionsOf:upToReadVersion:."
	aCollectionOfClusterVersions isEmpty ifTrue: [ ^ 0 ].
	^ (self segmentAt: aCollectionOfClusterVersions first objectId segment)
		copyVersionChain: aCollectionOfClusterVersions upToReadVersion: aNumberOrNil
]

{ #category : #accessing }
SoilObjectRepository >> firstSegment [
	^ segments first
]

{ #category : #accessing }
SoilObjectRepository >> flush [
	self segmentsDo: #flush
]

{ #category : #accessing }
SoilObjectRepository >> heapPositionOf: anObjectId [ 
	^ (self segmentAt: anObjectId segment)
		heapPositionAt: anObjectId index  
]

{ #category : #initialization }
SoilObjectRepository >> initializeFilesystem [
	| firstSegment |
	(self path / #segments) ensureCreateDirectory.
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
	"Build what #initializeFilesystem builds: an OrderedCollection of segments in
	ascending id order. Whatever ids are on disk are the ids - they are not
	positions, and nothing here assumes they run without a gap."

	| segmentPath ids |
	segmentPath := self path / #segments.
	segmentPath exists ifFalse: [ SoilSoilNotInitialized signal: 'soil instance on ', segmentPath pathString, ' has not been initialized' ].
	ids := ((segmentPath directories collect: [ :each | each basename asInteger ])
		reject: #isNil) asSortedCollection.
	(ids includes: 0) ifTrue: [
		metaSegment := self newMetaSegment
			open;
			yourself ].
	segments := OrderedCollection new.
	ids do: [ :id |
		id = 0 ifFalse: [
			segments add: (self newSegment
				id: id;
				open;
				yourself) ] ].
	^ segments
]

{ #category : #accessing }
SoilObjectRepository >> lockObjectId: aSOObjectId for: lockContext [
	^ (self segmentAt: aSOObjectId segment)
		lockObjectId: aSOObjectId for: lockContext
]

{ #category : #gc }
SoilObjectRepository >> makeGCClone [
	^ self class new
		soil: soil; 
		path: path, #gc;
		initializeFilesystem 
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
SoilObjectRepository >> path [

	^ path ifNil: [ 
		path := soil path ]
]

{ #category : #accessing }
SoilObjectRepository >> path: anObject [

	path := anObject
]

{ #category : #accessing }
SoilObjectRepository >> segmentAt: anInteger [
	"segment ids are ids, not positions into #segments - a SoilObjectId carries the
	id of the segment it lives in, so ids can never be renumbered and a segment that
	is ever removed has to leave its id vacant"

	^ anInteger == 0
		ifTrue: [ metaSegment ]
		ifFalse: [
			self segments
				detect: [ :each | each id = anInteger ]
				ifNone: [ SoilInvalidSegmentIndex signal: 'there is no segment ', anInteger printString ] ]
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

{ #category : #writing }
SoilObjectRepository >> writeContentsToDisk [
	soil setup isFsyncEnabled ifTrue: [  
		self segmentsDo: #writeContentsToDisk ]
]
