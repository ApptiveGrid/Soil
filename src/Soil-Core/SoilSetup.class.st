Class {
	#name : #SoilSetup,
	#superclass : #Object,
	#instVars : [
		'soil'
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
SoilSetup >> cacheRecords [
	self cacheRecords: self defaultCacheRecordsSize
]

{ #category : #caching }
SoilSetup >> cacheRecords: anInteger [
	self 
		cacheMetaRecords: anInteger;
		cacheObjectRecords: anInteger
]

{ #category : #accessing }
SoilSetup >> defaultCacheRecordsSize [
	^ 1000
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
SoilSetup >> soil: aSoil [ 
	soil := aSoil
]
