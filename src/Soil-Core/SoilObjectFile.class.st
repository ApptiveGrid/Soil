Class {
	#name : #SoilObjectFile,
	#superclass : #SoilSegmentFile,
	#category : #'Soil-Core-Files'
}

{ #category : #versions }
SoilObjectFile >> allRecords [
	| records pos record |
	records := OrderedCollection new.
	stream position: self recordStart.
	[ stream atEnd ] whileFalse: [ 
		pos := stream position.
		record := SoilPersistentClusterVersion readFrom: stream.
		records add: (pos -> record) ].
	^ records 
]

{ #category : #writing }
SoilObjectFile >> appendAllBytes: aCollection [
	"append each of aCollection of byte arrays and answer where each of them starts. One
	position, one write per record into the buffer and one flush for all of them: where
	moving the file position is not cheap, #appendBytes: per record was what an import of
	many records spent its time on"
	| position positions |
	^ mutex critical: [
		position := stream size.
		stream position: position.
		positions := aCollection collect: [ :bytes | | start |
			start := position.
			stream nextPutAll: bytes.
			position := position + bytes size.
			start ].
		stream flush.
		positions ]
]

{ #category : #writing }
SoilObjectFile >> appendBytes: aCollection [ 
	| position |
	^ mutex critical: [  
		position := stream size.
		stream position: position.
		stream nextPutAll: aCollection.
		stream flush.
		position ]
]

{ #category : #accessing }
SoilObjectFile >> atPosition: anInteger [ 
	| clusterVersion |
	^ mutex critical: [ 
		stream position: anInteger.
		clusterVersion := SoilPersistentClusterVersion readFrom: stream.
		(clusterVersion position = anInteger) ifFalse: [ 
			Error signal: 'position do not match' ].
		clusterVersion ]
]

{ #category : #accessing }
SoilObjectFile >> basicAtPosition: anInteger length: length [
	^ mutex critical: [ 
		stream position: anInteger.
		stream next: length ]
]

{ #category : #initialization }
SoilObjectFile >> initialize [
	super initialize.
	"Use mutex for now as we experience debugging problems with the semaphore"
	mutex := Mutex new
]

{ #category : #initialization }
SoilObjectFile >> initializeFilesystem [ 
	super initializeFilesystem.
	self writeContentsToDisk 
]

{ #category : #accessing }
SoilObjectFile >> path [
	^ segment path / #objects
]

{ #category : #writing }
SoilObjectFile >> prefix [ 
	^ 'SOIL|OBJECT ' asByteArray
]

{ #category : #accessing }
SoilObjectFile >> recordStart [
	^ (segment id == 0)
		ifTrue: [ self headerSize + 16 ]
		ifFalse: [ self headerSize + 8 ]
]

{ #category : #accessing }
SoilObjectFile >> size [ 
	^ stream size
]

{ #category : #versions }
SoilObjectFile >> versionSize [
	^ 8
]

{ #category : #initialization }
SoilObjectFile >> writeContentsToDisk [ 
	(segment notNil and: [ segment soil setup isFsyncEnabled  ]) ifTrue: [
		stream sync ]
]
