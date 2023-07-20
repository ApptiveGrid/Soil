Class {
	#name : #SoilObjectIndexFile,
	#superclass : #SoilSegmentFile,
	#instVars : [
		'semaphore'
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
	^ semaphore critical: [  
		stream position: (self indexPositionAt: index).
		(stream next: 8) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> at: index putPosition: position [ 
	(position > 0) ifFalse: [ SoilIndexOutOfRange signal: 'object index needs to be larger than zero' ].
	semaphore critical: [  
		stream position: (self indexPositionAt: index).
		stream  nextPutAll: (position asByteArrayOfSize: self objectIndexSize).
		stream flush ]
]

{ #category : #accessing }
SoilObjectIndexFile >> indexPositionAt: anInteger [ 
	(anInteger > 0) ifFalse: [ SoilIndexOutOfRange signal: 'object index needs to be larger than zero' ].
	^ self headerSize + self objectIndexSize + (anInteger - 1 * self objectIndexSize)
]

{ #category : #initialization }
SoilObjectIndexFile >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilObjectIndexFile >> initializeStart [
	self lastObjectIndex: 1.
	"intialize the slot for the root object"
	self at: 1 putPosition: 1.
]

{ #category : #accessing }
SoilObjectIndexFile >> lastObjectIndex [
	^ semaphore critical: [  
		stream position: self headerSize.
		(stream next: self objectIndexSize) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> lastObjectIndex: anInteger [ 
	semaphore critical: [  
		stream 
			position: self headerSize;
			nextPutAll: (anInteger asByteArrayOfSize: self objectIndexSize);
			flush ]
]

{ #category : #locking }
SoilObjectIndexFile >> lockLastObjectIndexFor: lockContext [ 
	^ semaphore critical: [  
		stream 
			lockFrom: self headerSize 
			length: self objectIndexSize
			for: lockContext ]
]

{ #category : #locking }
SoilObjectIndexFile >> lockObjectId: aSOObjectId for: lockContext [
	^ semaphore critical: [  
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

{ #category : #accessing }
SoilObjectIndexFile >> path [
	^ segment path / #index
]

{ #category : #accessing }
SoilObjectIndexFile >> positionAt: anInteger [ 
	^ semaphore critical: [  
		stream position: (self indexPositionAt: anInteger).
		(stream next: self objectIndexSize) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> prefix [ 
	^ 'SOIL|OBJECT INDEX' asByteArray
]
