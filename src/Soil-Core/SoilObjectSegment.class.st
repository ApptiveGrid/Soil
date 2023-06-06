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
	^ aSoilVisitor visitObjectSegment: self
]

{ #category : #adding }
SoilObjectSegment >> addNewRaw: aByteArray [ 
	| objectIndex |
	objectIndex := self indexFile nextIndex.
	self 
		at: objectIndex 
		putBytes: aByteArray.
	^ objectIndex 
]

{ #category : #'as yet unclassified' }
SoilObjectSegment >> allVersionsAt: index [ 
	| obj versions |
	obj := self at: index.
	versions := OrderedCollection new.
	versions add: obj.
	[ obj previousVersionPosition isZero ] whileFalse: [ 
		obj := self objectFile atPosition: obj previousVersionPosition.
		versions add: obj ].
	^ versions
]

{ #category : #'as yet unclassified' }
SoilObjectSegment >> allocateNextIndex [
	^ self indexFile allocateNewIndex
]

{ #category : #accessing }
SoilObjectSegment >> at: anInteger [ 
	| position |
	position := self indexFile positionAt: anInteger.
	^ (self objectFile atPosition: position) ifNotNil: [ :record | 
		record objectId: (SoilObjectId segment: id index: anInteger) ]
]

{ #category : #accessing }
SoilObjectSegment >> at: anInteger putBytes: bytes [ 
	| position |
	position := self objectFile size.
	objectFile appendBytes: bytes.
	self indexFile at: anInteger putPosition: position.
	^ position
]

{ #category : #accessing }
SoilObjectSegment >> at: index version: version [ 
	| record |
	record := self at: index.
	[ record version <= version ] whileFalse: [ 
		record hasPreviousVersion ifFalse: [ ^ nil ].
		record := self objectFile atPosition: record previousVersionPosition ].
	^ record
]

{ #category : #accessing }
SoilObjectSegment >> basicAt: anInteger length:  length [
	| position |
	position := self indexFile positionAt: anInteger.
	^ self objectFile basicAtPosition: position length: length
]

{ #category : #'initialize-release' }
SoilObjectSegment >> close [
	indexFile ifNotNil: [ 
		indexFile close ].
	objectFile ifNotNil: [ 
		objectFile close ].
	indexManager ifNotNil: [ 
		indexManager close ]
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
SoilObjectSegment >> indexAt: anIndexedObject ifAbsent: aBlock [
	^ self indexManager 
		at: anIndexedObject 
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilObjectSegment >> indexFile [
	^ indexFile ifNil: [
		indexFile := SoilObjectIndexFile new 
			segment: self;
			open ]
]

{ #category : #accessing }
SoilObjectSegment >> indexFile: aSOObjectIndexFile [ 
	indexFile := aSOObjectIndexFile
]

{ #category : #accessing }
SoilObjectSegment >> indexManager [ 
	^ indexManager ifNil: [ 
		indexManager := SoilIndexManager new 
			segment: self;
			open;
			yourself ]
]

{ #category : #initialization }
SoilObjectSegment >> initializeFilesystem [
	self path ensureCreateDirectory.
	SoilObjectFile new
		segment: self;
		initializeFilesystem;
		close.
	SoilObjectIndexFile new
		segment: self;
		initializeFilesystem;
		close.
	SoilIndexManager new 
		segment: self;
		initializeFilesystem;
		close
]

{ #category : #accessing }
SoilObjectSegment >> lastObjectIndex [ 
	^ self indexFile lastObjectIndex
]

{ #category : #accessing }
SoilObjectSegment >> lastObjectIndex: anInteger [ 
	^ indexFile lastObjectIndex: anInteger 
]

{ #category : #locking }
SoilObjectSegment >> lockAppendingFor: lockContext [
	^ self objectFile lockAppendingFor: lockContext
]

{ #category : #accessing }
SoilObjectSegment >> lockLastObjectIndexFor: lockContext [ 
	^ indexFile lockLastObjectIndexFor: lockContext 
]

{ #category : #'as yet unclassified' }
SoilObjectSegment >> lockObjectId: aSOObjectId for: lockContext [ 
	^ self indexFile lockObjectId: aSOObjectId for: lockContext 
]

{ #category : #ids }
SoilObjectSegment >> newObjectId [
	^ SoilObjectId segment: id index: 0 
]

{ #category : #accessing }
SoilObjectSegment >> objectFile [
	^ objectFile ifNil: [ 
		objectFile := SoilObjectFile new
			segment: self;
			open ]
]

{ #category : #accessing }
SoilObjectSegment >> objectFile: aSOObjectFile [ 
	objectFile := aSOObjectFile
]

{ #category : #accessing }
SoilObjectSegment >> objectRepository: aSOObjectRepository [ 
	objectRepository := aSOObjectRepository 
]

{ #category : #accessing }
SoilObjectSegment >> path [
	^ objectRepository soil path / #segments / self id asString
]

{ #category : #printing }
SoilObjectSegment >> printOn: aStream [ 
	aStream << 'segment #' << id asString 
]

{ #category : #'as yet unclassified' }
SoilObjectSegment >> registerIndexedObject: aSoilSkipListDictionary [ 
	^ self indexManager registerIndexedObject: aSoilSkipListDictionary 
]

{ #category : #accessing }
SoilObjectSegment >> soil [
	^ objectRepository soil
]

{ #category : #accessing }
SoilObjectSegment >> soil: aSoil [ 
	soil := aSoil
]
