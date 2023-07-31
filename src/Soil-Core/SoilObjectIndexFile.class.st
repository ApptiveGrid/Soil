Class {
	#name : #SoilObjectIndexFile,
	#superclass : #SoilSegmentFile,
	#instVars : [
		'mutex',
		'currentLastObjectIndex'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #initialization }
SoilObjectIndexFile >> allocateNewIndex [
	| lastIndex |
	lastIndex := self lastObjectIndex + 1.
	self lastObjectIndex: lastIndex.
	^ lastIndex
]

{ #category : #accessing }
SoilObjectIndexFile >> at: index [ 
	^ mutex critical: [  
		stream position: (self indexPositionAt: index).
		(stream next: 8) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> at: index putPosition: position [ 
	(position > 0) ifFalse: [ SoilIndexOutOfRange signal: 'object index needs to be larger than zero' ].
	mutex critical: [  
		stream position: (self indexPositionAt: index).
		stream  nextPutAll: (position asByteArrayOfSize: self objectIndexSize).
		stream flush ]
]

{ #category : #accessing }
SoilObjectIndexFile >> basicLastObjectIndex: anInteger [ 
	mutex critical: [
		stream 
			position: self headerSize;
			nextPutAll: (anInteger asByteArrayOfSize: self objectIndexSize);
			flush ]
]

{ #category : #accessing }
SoilObjectIndexFile >> indexPositionAt: anInteger [ 
	(anInteger > 0) ifFalse: [ SoilIndexOutOfRange signal: 'object index needs to be larger than zero' ].
	^ self headerSize + self objectIndexSize + (anInteger - 1 * self objectIndexSize)
]

{ #category : #initialization }
SoilObjectIndexFile >> initialize [ 
	super initialize.
	"Use mutex for now as we experience debugging problems with the semaphore"
	mutex := Mutex new
]

{ #category : #initialization }
SoilObjectIndexFile >> initializeStart [
	currentLastObjectIndex := 1.
	self basicLastObjectIndex: 1.
	"intialize the slot for the root object"
	self at: 1 putPosition: 1.
]

{ #category : #accessing }
SoilObjectIndexFile >> lastObjectIndex [
	^ mutex critical: [  
		stream position: self headerSize.
		(stream next: self objectIndexSize) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> lastObjectIndex: anInteger [ 
	"we memory track object indexes to ensure the index is only 
	growing and not fully rely on the stream being up-to-date"
	(currentLastObjectIndex < anInteger) ifFalse: [ 
		SoilInvalidSegmentIndex signal: 'segment indexes can only grow' ]. 
	"last resort check if object index on disk is also valid"
	self validateLastObjectIndex: anInteger.
	self basicLastObjectIndex: anInteger.
	currentLastObjectIndex := anInteger 
]

{ #category : #locking }
SoilObjectIndexFile >> lockLastObjectIndexFor: lockContext [ 
	^ mutex critical: [  
		stream 
			lockFrom: self headerSize 
			length: self objectIndexSize
			for: lockContext ]
]

{ #category : #locking }
SoilObjectIndexFile >> lockObjectId: aSOObjectId for: lockContext [
	^ mutex critical: [  
		stream 
			lockFrom: (self indexPositionAt: aSOObjectId index) 
			length: self objectIndexSize  
			for: lockContext ]
]

{ #category : #accessing }
SoilObjectIndexFile >> nextIndex [
	^ self lastObjectIndex + 1
]

{ #category : #accessing }
SoilObjectIndexFile >> objectIndexSize [
	^ 8
]

{ #category : #'instance creation' }
SoilObjectIndexFile >> open [ 
	super open.
	currentLastObjectIndex := self lastObjectIndex
]

{ #category : #accessing }
SoilObjectIndexFile >> path [
	^ segment path / #index
]

{ #category : #accessing }
SoilObjectIndexFile >> positionAt: anInteger [ 
	^ mutex critical: [  
		stream position: (self indexPositionAt: anInteger).
		(stream next: self objectIndexSize) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> prefix [ 
	^ 'SOIL|OBJECT INDEX' asByteArray
]

{ #category : #'private - decoding' }
SoilObjectIndexFile >> readHeader [ 
	super readHeader.
	currentLastObjectIndex := 0
]

{ #category : #validating }
SoilObjectIndexFile >> validateLastObjectIndex: anInteger [ 
	| fileIndex |
	fileIndex := self lastObjectIndex.
	(fileIndex < anInteger) ifFalse: [ 
		SoilInvalidSegmentIndex signal: 'segment indexes can only grow. ', anInteger printString, ' is smaller than the on-disk index ', fileIndex printString ] 
]
