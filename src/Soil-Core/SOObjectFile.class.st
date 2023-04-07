Class {
	#name : #SOObjectFile,
	#superclass : #SOSegmentFile,
	#instVars : [
		'fuelVersion',
		'semaphore'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #'as yet unclassified' }
SOObjectFile >> appendBytes: aCollection [ 
	semaphore critical: [  
		stream position: stream size.
		stream nextPutAll: aCollection.
		stream flush ]
]

{ #category : #accessing }
SOObjectFile >> atPosition: anInteger [ 
	| clusterVersion |
	^ semaphore critical: [ 
		stream position: anInteger.
		clusterVersion := SOPersistentClusterVersion readFrom: stream.
		(clusterVersion position = anInteger) ifFalse: [ 
			Error signal: 'position do not match' ].
		clusterVersion ]
]

{ #category : #accessing }
SOObjectFile >> basicAtPosition: anInteger length: length [
	^ semaphore critical: [ 
		stream position: anInteger.
		stream next: length ]
]

{ #category : #accessing }
SOObjectFile >> fuelVersion [
	^ fuelVersion
]

{ #category : #accessing }
SOObjectFile >> fuelVersion: anInteger [ 
	self flag: #todo.
	"fuel is gone so should this"
	stream position: self prefix size + self fileVersionSize.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fuelVersionSize)
]

{ #category : #'as yet unclassified' }
SOObjectFile >> fuelVersionSize [
	^ 2
]

{ #category : #writing }
SOObjectFile >> headerSize [ 
	"this header adds the fuel version"
	^ super headerSize + self fuelVersionSize 
]

{ #category : #initialization }
SOObjectFile >> initialize [
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SOObjectFile >> initializeHeader [
	super initializeHeader.
	self fuelVersion: 1
]

{ #category : #initialization }
SOObjectFile >> initializeStart [

]

{ #category : #accessing }
SOObjectFile >> path [
	^ segment path / #objects
]

{ #category : #writing }
SOObjectFile >> prefix [ 
	^ 'SOIL|OBJECT ' asByteArray
]

{ #category : #'private - decoding' }
SOObjectFile >> readHeader [
	super readHeader.
	fuelVersion := (stream next: self fuelVersionSize) asInteger
]

{ #category : #accessing }
SOObjectFile >> size [ 
	^ stream size
]

{ #category : #versions }
SOObjectFile >> versionSize [
	^ 8
]
