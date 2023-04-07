Class {
	#name : #SOObjectIndexFile,
	#superclass : #SOSegmentFile,
	#instVars : [
		'lastObjectIndex',
		'semaphore'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> allocateNewIndex [
	| lastIndex |
	lastIndex := self lastObjectIndex + 1.
	self lastObjectIndex: lastIndex.
	^ lastIndex
]

{ #category : #accessing }
SOObjectIndexFile >> at: index [ 
	^ semaphore critical: [  
		stream position: (self indexPositionAt: index).
		(stream next: 8) asInteger ]
]

{ #category : #accessing }
SOObjectIndexFile >> at: index putPosition: position [ 
	^ semaphore critical: [  
		stream position: (self indexPositionAt: index).
		stream  nextPutAll: (position asByteArrayOfSize: self objectIndexSize).
		stream flush ]
]

{ #category : #accessing }
SOObjectIndexFile >> indexPositionAt: anInteger [ 
	(anInteger > 0) ifFalse: [ SOIndexOutOfRange signal: 'object index needs to be larger than zero' ].
	^ self headerSize + self objectIndexSize + (anInteger - 1 * self objectIndexSize)
]

{ #category : #initialization }
SOObjectIndexFile >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SOObjectIndexFile >> initializeStart [
	self lastObjectIndex: 1.
	"intialize the slot for the root object"
	self at: 1 putPosition: 0.
]

{ #category : #accessing }
SOObjectIndexFile >> lastObjectIndex [
	^ lastObjectIndex ifNil: [ 
		stream position: self headerSize.
		lastObjectIndex := (stream next: self objectIndexSize) asInteger ]
]

{ #category : #accessing }
SOObjectIndexFile >> lastObjectIndex: anInteger [ 
	semaphore critical: [  
		stream 
			position: self headerSize;
			nextPutAll: (anInteger asByteArrayOfSize: self objectIndexSize);
			flush.
		lastObjectIndex := anInteger ]
]

{ #category : #lockgin }
SOObjectIndexFile >> lockLastObjectIndexFor: lockContext [ 
	^ semaphore critical: [  
		stream 
			lockFrom: self headerSize 
			length: self objectIndexSize
			for: lockContext ]
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> lockObjectId: aSOObjectId for: lockContext [
	semaphore critical: [  
		stream 
			lockFrom: (self indexPositionAt: aSOObjectId index) 
			length: self objectIndexSize  
			for: lockContext ]
]

{ #category : #accessing }
SOObjectIndexFile >> nextIndex [
	^ self lastObjectIndex + 1
]

{ #category : #accessing }
SOObjectIndexFile >> objectIndexSize [
	^ 8
]

{ #category : #accessing }
SOObjectIndexFile >> path [
	^ segment path / #index
]

{ #category : #accessing }
SOObjectIndexFile >> positionAt: anInteger [ 
	^ semaphore critical: [  
		stream position: (self indexPositionAt: anInteger).
		(stream next: self objectIndexSize) asInteger ]
]

{ #category : #accessing }
SOObjectIndexFile >> prefix [ 
	^ 'SOIL|OBJECT INDEX' asByteArray
]
