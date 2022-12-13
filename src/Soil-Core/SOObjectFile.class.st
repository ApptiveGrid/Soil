Class {
	#name : #SOObjectFile,
	#superclass : #SOSegmentFile,
	#instVars : [
		'id',
		'fuelVersion'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #'as yet unclassified' }
SOObjectFile >> appendBytes: aCollection [ 
	stream position: stream size.
	stream nextPutAll: aCollection.
	stream flush
]

{ #category : #accessing }
SOObjectFile >> atPosition: anInteger [ 
	stream position: anInteger.
	^ SOObjectRecord readFrom: stream
]

{ #category : #accessing }
SOObjectFile >> basicAtPosition: anInteger length: length [
	stream position: anInteger.
	^ stream next: length
]

{ #category : #'initialize-release' }
SOObjectFile >> close [
	stream ifNotNil: [ 
		stream close ]
]

{ #category : #accessing }
SOObjectFile >> fuelVersion [
	^ fuelVersion
]

{ #category : #accessing }
SOObjectFile >> fuelVersion: anInteger [ 
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
