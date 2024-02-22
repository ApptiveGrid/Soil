Class {
	#name : 'SoilObjectSegmentTest',
	#superclass : 'TestCase',
	#category : 'Soil-Core-Tests',
	#package : 'Soil-Core-Tests'
}

{ #category : 'tests' }
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

{ #category : 'tests' }
SoilObjectSegmentTest >> testStoreObject [ 
	| segment obj newIndex |
	segment := self newMemorySegment.
	newIndex := segment lastObjectIndex + 2.
	segment at: newIndex putBytes: #[ 1 2 3 ].
	obj := (segment basicAt: newIndex length: 3).
	self assert: obj equals: #[ 1 2 3 ]
]
