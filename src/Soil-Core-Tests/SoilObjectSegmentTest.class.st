Class {
	#name : #SoilObjectSegmentTest,
	#superclass : #TestCase,
	#instVars : [
		'reference',
		'label'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #tests }
SoilObjectSegmentTest >> newMemorySegment [
	| segment |
	segment := SoilObjectSegment new.
	segment indexFile: (SoilObjectIndexFile new 
		stream: (ReadWriteStream with: ByteArray new);
		initializeFilesystem;
		yourself).
	segment objectFile: (SoilObjectFile new 
		stream: (ReadWriteStream with: ByteArray new);
		initializeFilesystem;
		yourself).
	^ segment
]

{ #category : #tests }
SoilObjectSegmentTest >> testStoreObject [ 
	| segment id obj |
	segment := self newMemorySegment.
	id := segment addNewRaw: #[ 1 2 3 ].
	obj := (segment basicAt: id length: 3).
	self assert: obj equals: #[ 1 2 3 ]
]
