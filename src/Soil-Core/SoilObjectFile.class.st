Class {
	#name : #SoilObjectFile,
	#superclass : #SoilSegmentFile,
	#instVars : [
		'fuelVersion',
		'semaphore'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #'as yet unclassified' }
SoilObjectFile >> appendBytes: aCollection [ 
	semaphore critical: [  
		stream position: stream size.
		stream nextPutAll: aCollection.
		stream flush ]
]

{ #category : #accessing }
SoilObjectFile >> atPosition: anInteger [ 
	| clusterVersion |
	^ semaphore critical: [ 
		stream position: anInteger.
		clusterVersion := SoilPersistentClusterVersion readFrom: stream.
		(clusterVersion position = anInteger) ifFalse: [ 
			Error signal: 'position do not match' ].
		clusterVersion ]
]

{ #category : #accessing }
SoilObjectFile >> basicAtPosition: anInteger length: length [
	^ semaphore critical: [ 
		stream position: anInteger.
		stream next: length ]
]

{ #category : #accessing }
SoilObjectFile >> fuelVersion [
	^ fuelVersion
]

{ #category : #accessing }
SoilObjectFile >> fuelVersion: anInteger [ 
	self flag: #todo.
	"fuel is gone so should this"
	stream position: self prefix size + self fileVersionSize.
	stream nextPutAll: (anInteger asByteArrayOfSize: self fuelVersionSize)
]

{ #category : #'as yet unclassified' }
SoilObjectFile >> fuelVersionSize [
	^ 2
]

{ #category : #writing }
SoilObjectFile >> headerSize [ 
	"this header adds the fuel version"
	^ super headerSize + self fuelVersionSize 
]

{ #category : #initialization }
SoilObjectFile >> initialize [
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilObjectFile >> initializeHeader [
	super initializeHeader.
	self fuelVersion: 1
]

{ #category : #initialization }
SoilObjectFile >> initializeStart [

]

{ #category : #accessing }
SoilObjectFile >> path [
	^ segment path / #objects
]

{ #category : #writing }
SoilObjectFile >> prefix [ 
	^ 'SOIL|OBJECT ' asByteArray
]

{ #category : #'private - decoding' }
SoilObjectFile >> readHeader [
	super readHeader.
	fuelVersion := (stream next: self fuelVersionSize) asInteger
]

{ #category : #accessing }
SoilObjectFile >> size [ 
	^ stream size
]

{ #category : #versions }
SoilObjectFile >> versionSize [
	^ 8
]
