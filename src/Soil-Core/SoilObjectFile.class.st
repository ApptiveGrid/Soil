Class {
	#name : #SoilObjectFile,
	#superclass : #SoilSegmentFile,
	#category : #'Soil-Core-Files'
}

{ #category : #'as yet unclassified' }
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

{ #category : #accessing }
SoilObjectFile >> path [
	^ segment path / #objects
]

{ #category : #writing }
SoilObjectFile >> prefix [ 
	^ 'SOIL|OBJECT ' asByteArray
]

{ #category : #'as yet unclassified' }
SoilObjectFile >> recordStart [
	^ (segment id = 0)
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
