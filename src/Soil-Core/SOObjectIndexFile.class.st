Class {
	#name : #SOObjectIndexFile,
	#superclass : #SOBinaryFile,
	#instVars : [
		'lastObjectIndex'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOObjectIndexFile >> at: index putPosition: position [ 
	stream position: (self indexPositionAt: index).
	stream  nextPutAll: (position asByteArrayOfSize: self objectIndexSize)
]

{ #category : #accessing }
SOObjectIndexFile >> indexPositionAt: anInteger [ 
	^ self headerSize + self objectIndexSize + (anInteger - 1 * self objectIndexSize)
]

{ #category : #initialization }
SOObjectIndexFile >> initializeStart [
	self lastObjectIndex: 0
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
		nextPutAll: (anInteger asByteArrayOfSize: self objectIndexSize).
	lastObjectIndex := anInteger 
]

{ #category : #'as yet unclassified' }
SOObjectIndexFile >> objectIndexSize [
	^ 8
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
