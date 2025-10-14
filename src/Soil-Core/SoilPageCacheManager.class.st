Class {
	#name : #SoilPageCacheManager,
	#superclass : #Object,
	#instVars : [
		'segment',
		'indexes',
		'semaphore'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilPageCacheManager class >> indexClassFromFile: aFileReference [ 
	| stream pageCode headerPage |
	stream := aFileReference binaryReadStream.
	pageCode := stream next.
	stream close.
	headerPage :={ SoilSkipListHeaderPage . SoilBTreeHeaderPage } detect: [ :each | each pageCode = pageCode ].
	^ headerPage indexClass
]

{ #category : #visiting }
SoilPageCacheManager >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitIndexManager: self 
]

{ #category : #accessing }
SoilIndexManager >> at: indexId [ 
	^ self 
		at: indexId 
		ifAbsent: [ SoilIndexNotFound signal: 'index with id ', indexId asString, ' not found' ]
]

{ #category : #accessing }
SoilIndexManager >> at: indexId ifAbsent: aBlock [ 
	^ semaphore critical: [  
		indexes 
			at: indexId 
			ifAbsentPut: [ 
				self 
					loadPageCacheWithId: indexId 
					ifNone: aBlock  ] ]
		
]

{ #category : #accessing }
SoilPageCacheManager >> at: indexId put: aSoilIndex [
	^ semaphore critical: [  
		indexes 
			at: indexId
			put: aSoilIndex thePersistentInstance ]
]

{ #category : #'open/close' }
SoilPageCacheManager >> close [
	semaphore critical: [  
		indexes copy keysAndValuesDo: [ :id :index |
			index close.
			indexes removeKey: id ] ]
]

{ #category : #api }
SoilPageCacheManager >> createPageCacheWithId: indexId class: aClass [ 
	^ aClass new 
		path: (self pathFor: indexId);
		initializeFilesystem;
		initializeHeaderPage
]

{ #category : #accessing }
SoilPageCacheManager >> dirtyIndexes [
	^ indexes select: [ :each | each hasDirtyPages ]
]

{ #category : #accessing }
SoilPageCacheManager >> flush [
	self dirtyIndexes copy do: [ :index | 
		index cleanUpToVersion: (self soil transactionManager smallestReadVersion) ]
]

{ #category : #flushing }
SoilPageCacheManager >> flushIndexes [
	indexes do: #flushCachedPages
]

{ #category : #testing }
SoilPageCacheManager >> hasIndexId: aString [ 
	^ (self pathFor: aString) exists
]

{ #category : #accessing }
SoilPageCacheManager >> indexes [

	^ indexes
]

{ #category : #initialization }
SoilPageCacheManager >> initialize [ 
	super initialize.
	indexes := Dictionary new.
	semaphore := Semaphore forMutualExclusion
]

{ #category : #initialization }
SoilPageCacheManager >> initializeFilesystem [
	self path ensureCreateDirectory 
]

{ #category : #api }
SoilPageCacheManager >> loadPageCacheWithId: indexId ifNone: aBlock [
	| path |
	path := self path / indexId , #index.
	^ path exists
		ifTrue: [ 
			(self class indexClassFromFile: path) new 
				path: path ]
		ifFalse: [ aBlock value ]
]

{ #category : #'open/close' }
SoilPageCacheManager >> open [
	
]

{ #category : #accessing }
SoilPageCacheManager >> path [ 
	^ segment path / #indexes
]

{ #category : #accessing }
SoilPageCacheManager >> pathFor: indexId [ 
	^ self path / indexId , #index
]

{ #category : #accessing }
SoilPageCacheManager >> removePageCacheWithId: indexId [ 
	^ semaphore critical: [  
		(indexes 
			removeKey: indexId
			ifAbsent: [  ]) close ]
]

{ #category : #accessing }
SoilPageCacheManager >> segment [
	^ segment
]

{ #category : #accessing }
SoilPageCacheManager >> segment: aSOObjectSegment [ 
	segment := aSOObjectSegment 
]

{ #category : #accessing }
SoilPageCacheManager >> soil [ 
	^ segment soil 
]

{ #category : #writing }
SoilPageCacheManager >> writeContentsToDisk [
	segment soil setup isFsyncEnabled ifTrue: [  
		self indexes do: [ :each | each writeContentsToDisk ] ]
]
