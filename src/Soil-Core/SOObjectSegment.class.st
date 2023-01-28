Class {
	#name : #SOObjectSegment,
	#superclass : #Object,
	#instVars : [
		'id',
		'soil',
		'objectRepository',
		'indexFile',
		'objectFile'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SOObjectSegment >> addNewRaw: aByteArray [ 
	| objectIndex |
	objectIndex := self indexFile nextIndex.
	self 
		at: objectIndex 
		putBytes: aByteArray.
	^ objectIndex 
]

{ #category : #'as yet unclassified' }
SOObjectSegment >> allVersionsOf: aSOObjectId [ 
	| obj versions |
	obj := self at: aSOObjectId index.
	versions := OrderedCollection new.
	versions add: obj.
	[ obj previousVersionPosition isZero ] whileFalse: [ 
		obj := self objectFile atPosition: obj previousVersionPosition.
		versions add: obj ].
	^ versions
]

{ #category : #'as yet unclassified' }
SOObjectSegment >> allocateNextIndex [
	^ self indexFile allocateNewIndex
]

{ #category : #accessing }
SOObjectSegment >> at: anInteger [ 
	| position |
	position := self indexFile positionAt: anInteger.
	^ self objectFile atPosition: position
]

{ #category : #accessing }
SOObjectSegment >> at: anInteger putBytes: bytes [ 
	| position |
	position := self objectFile size.
	objectFile appendBytes: bytes.
	self indexFile at: anInteger putPosition: position.
	^ bytes
]

{ #category : #accessing }
SOObjectSegment >> at: index version: version [ 
	| record |
	record := self at: index.
	[ record version <= version ] whileFalse: [ 
		record hasPreviousVersion ifFalse: [ ^ nil ].
		record := self objectFile atPosition: record previousVersionPosition ].
	^ record
]

{ #category : #accessing }
SOObjectSegment >> basicAt: anInteger length:  length [
	| position |
	position := self indexFile positionAt: anInteger.
	^ self objectFile basicAtPosition: position length: length
]

{ #category : #'initialize-release' }
SOObjectSegment >> close [
	indexFile ifNotNil: [ 
		indexFile close ].
	objectFile ifNotNil: [ 
		objectFile close ]
]

{ #category : #accessing }
SOObjectSegment >> id [

	^ id ifNil: [ 1 ]
]

{ #category : #accessing }
SOObjectSegment >> id: anObject [

	id := anObject
]

{ #category : #accessing }
SOObjectSegment >> indexFile [
	^ indexFile ifNil: [
		indexFile := SOObjectIndexFile new 
			segment: self;
			open ]
]

{ #category : #accessing }
SOObjectSegment >> indexFile: aSOObjectIndexFile [ 
	indexFile := aSOObjectIndexFile
]

{ #category : #initialization }
SOObjectSegment >> initializeFilesystem [
	self path ensureCreateDirectory.
	SOObjectFile new
		segment: self;
		initializeFilesystem;
		close.
	SOObjectIndexFile new
		segment: self;
		initializeFilesystem;
		close
]

{ #category : #accessing }
SOObjectSegment >> lastObjectIndex [ 
	^ self indexFile lastObjectIndex
]

{ #category : #'as yet unclassified' }
SOObjectSegment >> lockObjectId: aSOObjectId for: lockContext [ 
	^ self indexFile lockObjectId: aSOObjectId for: lockContext 
]

{ #category : #ids }
SOObjectSegment >> newObjectId [
	^ SOObjectId segment: id index: 0 
]

{ #category : #accessing }
SOObjectSegment >> objectFile [
	^ objectFile ifNil: [ 
		objectFile := SOObjectFile new
			segment: self;
			open ]
]

{ #category : #accessing }
SOObjectSegment >> objectFile: aSOObjectFile [ 
	objectFile := aSOObjectFile
]

{ #category : #accessing }
SOObjectSegment >> objectRepository: aSOObjectRepository [ 
	objectRepository := aSOObjectRepository 
]

{ #category : #accessing }
SOObjectSegment >> path [
	^ objectRepository soil path / #segments / self id asString
]

{ #category : #printing }
SOObjectSegment >> printOn: aStream [ 
	aStream << 'segment #' << id asString 
]

{ #category : #accessing }
SOObjectSegment >> soil: aSoil [ 
	soil := aSoil
]
