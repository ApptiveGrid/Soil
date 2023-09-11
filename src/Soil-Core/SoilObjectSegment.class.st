Class {
	#name : #SoilObjectSegment,
	#superclass : #Object,
	#instVars : [
		'id',
		'soil',
		'objectRepository',
		'indexFile',
		'objectFile',
		'indexManager'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilObjectSegment >> acceptSoil: aSoilVisitor [ 
	^ self isMeta 
		ifTrue: [ aSoilVisitor visitMetaSegment: self ]
		ifFalse: [ aSoilVisitor visitObjectSegment: self ]
]

{ #category : #adding }
SoilObjectSegment >> addNewRaw: aByteArray [ 
	| objectIndex |
	objectIndex := indexFile nextIndex.
	self 
		at: objectIndex 
		putBytes: aByteArray.
	^ objectIndex 
]

{ #category : #accessing }
SoilObjectSegment >> allVersionsAt: index [ 
	| obj versions |
	obj := self at: index.
	versions := OrderedCollection new.
	versions add: obj.
	[ obj previousVersionPosition isZero ] whileFalse: [ 
		obj := objectFile atPosition: obj previousVersionPosition.
		versions add: obj ].
	^ versions
]

{ #category : #converting }
SoilObjectSegment >> asCachedSegment [
	^ (self as: SoilCachedObjectSegment)
		resetCache
]

{ #category : #accessing }
SoilObjectSegment >> at: anInteger [ 
	| position |
	position := indexFile positionAt: anInteger.
	^ (objectFile atPosition: position) ifNotNil: [ :record | 
		record objectId: (SoilObjectId segment: id index: anInteger) ]
]

{ #category : #accessing }
SoilObjectSegment >> at: anInteger putBytes: bytes [ 
	| position |
	position := objectFile size.
	objectFile appendBytes: bytes.
	indexFile at: anInteger putPosition: position.
	^ position
]

{ #category : #accessing }
SoilObjectSegment >> at: index version: version [ 
	| record |
	record := self at: index.
	[ record version <= version ] whileFalse: [ 
		record hasPreviousVersion ifFalse: [ ^ nil ].
		record := objectFile atPosition: record previousVersionPosition ].
	^ record
]

{ #category : #accessing }
SoilObjectSegment >> basicAt: anInteger length:  length [
	| position |
	position := indexFile positionAt: anInteger.
	^ objectFile basicAtPosition: position length: length
]

{ #category : #'open/close' }
SoilObjectSegment >> close [
	indexFile ifNotNil: [ 
		indexFile close ].
	objectFile ifNotNil: [ 
		objectFile close ].
	indexManager ifNotNil: [ 
		indexManager close ]
]

{ #category : #accessing }
SoilObjectSegment >> flushCachedObjectRecords [
	
]

{ #category : #flushing }
SoilObjectSegment >> flushIndexes [
	indexManager flushIndexes
]

{ #category : #accessing }
SoilObjectSegment >> heapPositionAt: anInteger [ 
	^ indexFile positionAt: anInteger
]

{ #category : #accessing }
SoilObjectSegment >> id [

	^ id ifNil: [ 1 ]
]

{ #category : #accessing }
SoilObjectSegment >> id: anObject [

	id := anObject
]

{ #category : #accessing }
SoilObjectSegment >> indexAt: indexId [ 
	^ self indexManager 
		at: indexId 
		ifAbsent: [ SoilIndexNotFound signal: 'index not found' ] 
]

{ #category : #accessing }
SoilObjectSegment >> indexAt: indexId ifAbsent: aBlock [
	^ self indexManager 
		at: indexId 
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilObjectSegment >> indexAt: indexId put: aSoilIndex [

	^ self indexManager at: indexId put: aSoilIndex
]

{ #category : #accessing }
SoilObjectSegment >> indexFile: aSOObjectIndexFile [ 
	indexFile := aSOObjectIndexFile
]

{ #category : #accessing }
SoilObjectSegment >> indexManager [ 
	^ indexManager
]

{ #category : #initialization }
SoilObjectSegment >> initializeFilesystem [
	self path ensureCreateDirectory.
	objectFile := SoilObjectFile new
		segment: self;
		initializeFilesystem.
	indexFile := SoilObjectIndexFile new
		segment: self;
		initializeFilesystem.
	indexManager := SoilIndexManager new 
		segment: self;
		initializeFilesystem;
		close
]

{ #category : #testing }
SoilObjectSegment >> isMeta [ 
	^ id = 0
]

{ #category : #accessing }
SoilObjectSegment >> lastObjectIndex [ 
	^ indexFile lastObjectIndex
]

{ #category : #accessing }
SoilObjectSegment >> lastObjectIndex: anInteger [ 
	^ indexFile lastObjectIndex: anInteger 
]

{ #category : #locking }
SoilObjectSegment >> lockAppendingFor: lockContext [
	^ objectFile lockAppendingFor: lockContext
]

{ #category : #accessing }
SoilObjectSegment >> lockLastObjectIndexFor: lockContext [ 
	^ indexFile lockLastObjectIndexFor: lockContext 
]

{ #category : #accessing }
SoilObjectSegment >> lockObjectId: aSOObjectId for: lockContext [ 
	^ indexFile lockObjectId: aSOObjectId for: lockContext 
]

{ #category : #ids }
SoilObjectSegment >> newObjectId [
	^ SoilObjectId segment: id index: 0 
]

{ #category : #accessing }
SoilObjectSegment >> objectFile: aSOObjectFile [ 
	objectFile := aSOObjectFile
]

{ #category : #accessing }
SoilObjectSegment >> objectRepository: aSOObjectRepository [ 
	objectRepository := aSOObjectRepository 
]

{ #category : #'open/close' }
SoilObjectSegment >> open [ 
	indexFile := SoilObjectIndexFile new 
			segment: self;
			open.
	objectFile := SoilObjectFile new
			segment: self;
			open.
	indexManager := SoilIndexManager new 
			segment: self;
			open
]

{ #category : #accessing }
SoilObjectSegment >> path [
	^ objectRepository soil path / #segments / self id asString
]

{ #category : #printing }
SoilObjectSegment >> printOn: aStream [ 
	aStream << 'segment #' << id asString 
]

{ #category : #accessing }
SoilObjectSegment >> soil [
	^ objectRepository soil
]

{ #category : #accessing }
SoilObjectSegment >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #validating }
SoilObjectSegment >> validateLastObjectIndex: anInteger [ 
	indexFile validateLastObjectIndex: anInteger
]
