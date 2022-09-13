Class {
	#name : #SOObjectSegmentTest,
	#superclass : #TestCase,
	#instVars : [
		'reference',
		'label'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SOObjectSegmentTest >> newMemorySegment [
	| segment id obj |
	segment := SOObjectSegment new.
	segment indexFile: (SOObjectIndexFile new 
		stream: (ReadWriteStream with: ByteArray new);
		initializeDatabase;
		yourself).
	segment objectFile: (SOObjectFile new 
		stream: (ReadWriteStream with: ByteArray new);
		initializeDatabase;
		yourself).
	^ segment
]

{ #category : #tests }
SOObjectSegmentTest >> testStoreObject [ 
	| segment id obj |
	segment := self newMemorySegment.
	id := segment addNewRaw: #[ 1 2 3 ].
	obj := (segment basicAt: id length: 3).
	self assert: obj equals: #[ 1 2 3 ]
]
