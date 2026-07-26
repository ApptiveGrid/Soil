Class {
	#name : #SoilObjectSegment,
	#superclass : #Object,
	#instVars : [
		'id',
		'objectRepository',
		'indexFile',
		'objectFile',
		'indexManager',
		'path'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilObjectSegment >> acceptSoil: aSoilVisitor [ 
	self isMetaSegment ifTrue: [ ^ aSoilVisitor visitMetaSegment: self ].
	self isFirstSegment ifTrue: [ ^ aSoilVisitor visitFirstSegment: self ].
	^ aSoilVisitor visitObjectSegment: self
]

{ #category : #accessing }
SoilObjectSegment >> allRecords [
	^ objectFile allRecords
]

{ #category : #accessing }
SoilObjectSegment >> allVersionsAt: index [ 
	| obj versions objectId |
	obj := self at: index.
	versions := OrderedCollection new.
	versions add: obj.
	objectId := obj objectId.
	[ obj previousVersionPosition == 0 ] whileFalse: [ 
		obj := objectFile atPosition: obj previousVersionPosition.
		obj objectId: objectId.
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
	^ (self basicAt: anInteger) ifNotNil: [ :record | 
		self soil notificationHandler recordRead: record.
		record ]
]

{ #category : #accessing }
SoilObjectSegment >> at: anInteger putBytes: bytes [ 
	| position |
	position := objectFile appendBytes: bytes.
	indexFile 
		at: anInteger 
		putPosition: position.
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
SoilObjectSegment >> basicAt: anInteger [ 
	^ self 
		basicAt: anInteger 
		ifAbsent: [  
			SoilIndexOutOfRange signal: 'no entry for object at ', id asString, ':', anInteger asString ].
	
]

{ #category : #accessing }
SoilObjectSegment >> basicAt: anInteger ifAbsent: aBlock [
	| position |
	position := indexFile positionAt: anInteger.
	position == 0 ifTrue: [  ^ aBlock value ].
	^ (objectFile atPosition: position) ifNotNil: [ :record | 
		record objectId: (SoilObjectId segment: id index: anInteger).
		record ]
]

{ #category : #accessing }
SoilObjectSegment >> basicAt: anInteger length:  length [
	| position |
	position := indexFile positionAt: anInteger.
	^ objectFile basicAtPosition: position length: length
]

{ #category : #accessing }
SoilObjectSegment >> basicAt: index version: version [ 
	| record |
	record := self basicAt: index.
	[ record version <= version ] whileFalse: [ 
		record hasPreviousVersion ifFalse: [ ^ nil ].
		record := objectFile atPosition: record previousVersionPosition ].
	^ record
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

{ #category : #copying }
SoilObjectSegment >> copyVersionChain: aCollectionOfClusterVersions [
	"Copy a version chain (ordered newest->oldest, as allVersionsAt: returns) into this
	segment, rebuilding previousVersionPosition; returns the position of the current
	(newest) version. Unlike SoilObjectRepository>>copyVersionChain: this targets *this*
	segment directly - e.g. a detached makeGCClone the repository cannot route to - and
	does not fire notificationHandler recordWritten: (GC-internal copy)."
	| position |
	position := 0.
	aCollectionOfClusterVersions reverseDo: [ :cluster | | copy |
		copy := cluster copyResetPreviousVersion.
		copy previousVersionPosition: position.
		position := self at: cluster objectId index putBytes: copy serialize ].
	^ position
]

{ #category : #copying }
SoilObjectSegment >> copyVersionChain: aCollectionOfClusterVersions upToReadVersion: aNumberOrNil [
	^ self copyVersionChain: (self keptVersionsOf: aCollectionOfClusterVersions upToReadVersion: aNumberOrNil)
]

{ #category : #accessing }
SoilObjectSegment >> flush [
	self indexManager flush
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

	^ self
		  indexAt: indexId
		  ifAbsent: [ SoilIndexNotFound signal: 'index not found' ]
]

{ #category : #accessing }
SoilObjectSegment >> indexAt: indexId ifAbsent: aBlock [
	^ self indexManager 
		at: indexId 
		ifAbsent: aBlock
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
SoilObjectSegment >> isFirstSegment [
	^ id == 1
]

{ #category : #testing }
SoilObjectSegment >> isMeta [ 
	^ id == 0
]

{ #category : #testing }
SoilObjectSegment >> isMetaSegment [
	^ id == 0
]

{ #category : #copying }
SoilObjectSegment >> keptVersionsOf: aCollectionOfClusterVersions upToReadVersion: aNumberOrNil [
	"Return the suffix (newest->oldest) of the chain still needed by a reader at
	aNumberOrNil (nil = no open transaction): a superseded version is droppable once the
	smallest read version has reached the version that superseded it. The current version
	is always kept. Mirrors SoilIndexCleaner>>canDiscardOldState:."
	| kept newerVersion |
	kept := OrderedCollection new.
	newerVersion := nil.
	aCollectionOfClusterVersions do: [ :each |
		(newerVersion notNil and: [ aNumberOrNil isNil or: [ aNumberOrNil >= newerVersion ] ])
			ifTrue: [ ^ kept ].
		kept add: each.
		newerVersion := each version ].
	^ kept
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

{ #category : #gc }
SoilObjectSegment >> makeGCClone [
	^ self class new 
		id: id;
		objectRepository: objectRepository;
		path: self path, #gc;
		initializeFilesystem 
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
	^ path ifNil: [
		path := objectRepository soil path / #segments / self id asString ]
]

{ #category : #accessing }
SoilObjectSegment >> path: anObject [

	path := anObject
]

{ #category : #printing }
SoilObjectSegment >> printOn: aStream [
	aStream << 'segment #' << id asString
]

{ #category : #gc }
SoilObjectSegment >> replaceWith: aCloneSegment [
	"Atomically swap this segment's on-disk file set (the directory .../segments/<id>)
	with a fully written clone produced by makeGCClone (.../segments/<id>.gc). Both share
	the same parent directory, so a single renameTo: is an atomic rename that also removes
	the clone directory - moveTo: would recursively COPY a directory and leave the source
	behind. Quiescent caller only; wrap build+replace in
	ifCurtailed: [ aCloneSegment path ensureDeleteAll ] so a crash before the rename leaves
	the original untouched and the clone a deletable orphan."
	| myPath |
	aCloneSegment flush; close.
	self close.
	myPath := self path.
	myPath ensureDeleteAll.
	aCloneSegment path renameTo: myPath basename.
	self open
]

{ #category : #accessing }
SoilObjectSegment >> soil [
	^ objectRepository soil
]

{ #category : #accessing }
SoilObjectSegment >> updateLastObjectIndex: anInteger [ 
	^ indexFile updateLastObjectIndex: anInteger 
]

{ #category : #validating }
SoilObjectSegment >> validateLastObjectIndex: anInteger [ 
	indexFile validateLastObjectIndex: anInteger
]

{ #category : #writing }
SoilObjectSegment >> writeContentsToDisk [
	self soil setup isFsyncEnabled ifTrue: [  
		indexFile writeContentsToDisk.
		objectFile writeContentsToDisk.
		self indexManager writeContentsToDisk ]
]
