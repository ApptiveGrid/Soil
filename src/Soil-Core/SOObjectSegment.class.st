Class {
	#name : #SOObjectSegment,
	#superclass : #Object,
	#instVars : [
		'id',
		'soil',
		'objectRepository',
		'index',
		'objects',
		'indexFile',
		'objectFile'
	],
	#category : #'Soil-Core'
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
SOObjectSegment >> at: anInteger putObject: anObject [ 
	| record |
	record := SOObjectRecord new 
		object: anObject;
		serializeObject.
	self halt.
]

{ #category : #accessing }
SOObjectSegment >> basicAt: anInteger length:  length [
	| position |
	position := self indexFile positionAt: anInteger.
	^ self objectFile basicAtPosition: position length: length
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
SOObjectSegment >> initializeDatabase [
	self path ensureCreateDirectory.
	SOObjectFile new
		segment: self;
		fileVersion: 1;
		fuelVersion: 1;
		initializeDatabase.
	SOObjectIndexFile new
		segment: self;
		fileVersion: 1;
		initializeDatabase 
]

{ #category : #'as yet unclassified' }
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

{ #category : #accessing }
SOObjectSegment >> soil: aSoil [ 
	soil := aSoil
]
