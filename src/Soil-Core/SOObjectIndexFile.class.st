Class {
	#name : #SOObjectIndexFile,
	#superclass : #SOSegmentFile,
	#instVars : [
		'lastObjectIndex'
	],
	#category : #'Soil-Core'
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
	stream position: (self indexPositionAt: index).
	^ (stream next: 8) asInteger 
]

{ #category : #accessing }
SOObjectIndexFile >> at: index putPosition: position [ 
	stream position: (self indexPositionAt: index).
	stream  nextPutAll: (position asByteArrayOfSize: self objectIndexSize).
	stream flush
]

{ #category : #'initialize-release' }
SOObjectIndexFile >> close [
	stream ifNotNil: [ 
		stream close ]
]

{ #category : #accessing }
SOObjectIndexFile >> indexPositionAt: anInteger [ 
	^ self headerSize + self objectIndexSize + (anInteger - 1 * self objectIndexSize)
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
	self stream 
		position: self headerSize;
		nextPutAll: (anInteger asByteArrayOfSize: self objectIndexSize);
		flush.
	lastObjectIndex := anInteger 
]

{ #category : #accessing }
SOObjectIndexFile >> nextIndex [
	^ self lastObjectIndex + 1
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> objectIndexSize [
	^ 8
]

{ #category : #accessing }
SOObjectIndexFile >> path [
	^ segment path / #index
]

{ #category : #accessing }
SOObjectIndexFile >> positionAt: anInteger [ 
	stream position: (self indexPositionAt: anInteger).
	^ (stream next: self objectIndexSize) asInteger
]

{ #category : #accessing }
SOObjectIndexFile >> prefix [ 
	^ 'SOIL|OBJECT INDEX' asByteArray
]
