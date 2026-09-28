Class {
	#name : #SoilObjectIndexFile,
	#superclass : #SoilSegmentFile,
	#instVars : [
		'currentLastObjectIndex'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #accessing }
SoilObjectIndexFile >> at: index [ 
	^ mutex critical: [  
		stream position: (self indexPositionAt: index).
		(stream next: 8) asInteger ]
]

{ #category : #accessing }
SoilObjectIndexFile >> putPositions: aCollectionOfAssociations [
	"index -> position for each of them, and one flush for all. The slots of indexes that
	follow each other lie next to each other in the file, so a run of them is written in
	one go - which is what the new objects of a commit are. When an index occurs twice,
	the later position is the one that stays, as with #at:putPosition: one after the other"
	| positions indexes |
	positions := Dictionary new.
	aCollectionOfAssociations do: [ :each |
		(each value > 0) ifFalse: [ SoilIndexOutOfRange signal: 'object index needs to be larger than zero' ].
		positions at: each key put: each value ].
	indexes := positions keys asSortedCollection asArray.
	mutex critical: [
		| runStart |
		runStart := 1.
		1 to: indexes size do: [ :n |
			(n = indexes size or: [ (indexes at: n + 1) ~= ((indexes at: n) + 1) ]) ifTrue: [
				stream position: (self indexPositionAt: (indexes at: runStart)).
				runStart to: n do: [ :each |
					stream nextPutAll: ((positions at: (indexes at: each)) asByteArrayOfSize: self objectIndexSize) ].
				runStart := n + 1 ] ].
		stream flush ]
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
	"just initialize the indexes with zero to be present"
	currentLastObjectIndex := 0.
	self basicLastObjectIndex: 0.
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

{ #category : #accessing }
SoilObjectIndexFile >> updateLastObjectIndex: anInteger [ 
	(anInteger <= currentLastObjectIndex) ifTrue: [ 
		"when doing a database recovery it is possible that the version 
		has been updated already. Prior updates that are replayed will
		have smaller numbers. We don't want to lower numbers so we just
		ignore them and let the journal catch up"
		^ self ]. 
	self lastObjectIndex: anInteger
]

{ #category : #validating }
SoilObjectIndexFile >> validateLastObjectIndex: anInteger [ 
	| fileIndex |
	fileIndex := self lastObjectIndex.
	(fileIndex < anInteger) ifFalse: [ 
		SoilInvalidSegmentIndex signal: 'segment indexes can only grow. ', anInteger printString, ' is smaller than the on-disk index ', fileIndex printString ] 
]

{ #category : #writing }
SoilObjectIndexFile >> writeContentsToDisk [
	(segment notNil and: [ segment soil setup isFsyncEnabled  ]) ifTrue: [
		stream sync ]
]
