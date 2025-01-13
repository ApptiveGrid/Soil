Class {
	#name : #SoilSetup,
	#superclass : #Object,
	#instVars : [
		'soil',
		'fsyncEnabled'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #caching }
SoilSetup >> cacheMetaRecords: anInteger [
	soil objectRepository cacheSegmentAt: 0 upTo: anInteger  
]

{ #category : #caching }
SoilSetup >> cacheObjectRecords: anInteger [
	1 to: soil objectRepository segments size do: [:n |
		soil objectRepository cacheSegmentAt: n upTo: anInteger ]
]

{ #category : #caching }
SoilSetup >> cacheObjectRecordsUsing: aBlock [
	1 to: soil objectRepository segments size do: [:n |
		soil objectRepository 
			cacheSegmentAt: n 
			using: aBlock  ]
]

{ #category : #caching }
SoilSetup >> cacheRecords [
	self cacheRecords: self defaultCacheRecordsSize
]

{ #category : #caching }
SoilSetup >> cacheRecords: anInteger [
	self 
		cacheMetaRecords: anInteger;
		cacheObjectRecords: anInteger
]

{ #category : #caching }
SoilSetup >> cacheSegmentAt: index maximumBytes: anInteger [
	self 
		cacheSegmentAt: index 
		using: [ :cache | 
			cache 
				computeWeight: #soilSizeInMemory;
				maximumWeight: anInteger ]
]

{ #category : #caching }
SoilSetup >> cacheSegmentAt: index using: aBlock [
	soil objectRepository 
		cacheSegmentAt: index
		using: aBlock
]

{ #category : #accessing }
SoilSetup >> defaultCacheRecordsSize [
	^ 1000
]

{ #category : #fsync }
SoilSetup >> disableFsync [ 
	fsyncEnabled := false
]

{ #category : #fsync }
SoilSetup >> enableFsync [ 
	fsyncEnabled := true
]

{ #category : #flushing }
SoilSetup >> flushCachedIndexes [
	soil objectRepository segmentsDo: [ :segment |
		segment flushIndexes ]
]

{ #category : #flushing }
SoilSetup >> flushCachedObjectRecords [
	soil objectRepository segmentsDo: [ :segment |
		segment flushCachedObjectRecords ]
]

{ #category : #flushing }
SoilSetup >> flushCaches [ 
	self 
		flushCachedObjectRecords;
		flushCachedIndexes
]

{ #category : #accessing }
SoilSetup >> fsyncEnabled: anObject [

	fsyncEnabled := anObject
]

{ #category : #initialization }
SoilSetup >> initialize [ 
	super initialize.
	fsyncEnabled := true
]

{ #category : #testing }
SoilSetup >> isFsyncEnabled [ 
	^ fsyncEnabled 
]

{ #category : #caching }
SoilSetup >> maxFragmentFiles:  anInteger [
	soil journal maxFragmentFiles: anInteger
]

{ #category : #accessing }
SoilSetup >> soil: aSoil [ 
	soil := aSoil
]
