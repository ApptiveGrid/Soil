Class {
	#name : #SoilObjectSegmentTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Model'
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
SoilObjectSegmentTest >> testAVersionChainThatCirclesIsRefused [ 
	"a record whose previous version is the record itself: the loop that collects a
	chain would never reach zero, and would keep every version it passed on the way.

	On disk rather than on the in-memory segment above: a ReadWriteStream can write a
	cluster version but not read one back, because #nextLengthEncodedInteger is on
	the reading streams only.

	The second record is made to point at the position it is about to land on, which
	is where the first one ends - an append goes to the end of the file, and that
	does not depend on what is being appended."
	| path soil segment index first second position |
	path := ('soil-circling-chain-' , UUID new asString) asFileReference.
	soil := Soil path: path.
	[ soil initializeFilesystem.
	segment := soil objectRepository segmentAt: 1.
	index := segment lastObjectIndex + 2.
	first := SoilPersistentClusterVersion new 
		version: 1;
		bytes: #[ 1 2 3 ];
		yourself.
	position := (segment at: index putBytes: first serialize) + first serialize size.
	second := SoilPersistentClusterVersion new 
		version: 2;
		bytes: #[ 4 5 6 ];
		yourself.
	second previousVersionPosition: position.
	self 
		assert: (segment at: index putBytes: second serialize) 
		equals: position.
	self 
		should: [ segment allVersionsAt: index ]
		raise: SoilDatabaseIsInconsistent ]
		ensure: [ 
			soil close.
			path exists ifTrue: [ path deleteAll ] ]
]


{ #category : #tests }
SoilObjectSegmentTest >> testStoreObject [ 
	| segment obj newIndex |
	segment := self newMemorySegment.
	newIndex := segment lastObjectIndex + 2.
	segment at: newIndex putBytes: #[ 1 2 3 ].
	obj := (segment basicAt: newIndex length: 3).
	self assert: obj equals: #[ 1 2 3 ]
]
