Class {
	#name : #SoilObjectFile,
	#superclass : #SoilSegmentFile,
	#category : #'Soil-Core-Files'
}

{ #category : #writing }
SoilObjectFile >> appendBytes: aCollection [ 
	mutex critical: [  
		stream position: stream size.
		stream nextPutAll: aCollection.
		stream flush ]
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

{ #category : #accessing }
SoilObjectFile >> size [ 
	^ stream size
]

{ #category : #versions }
SoilObjectFile >> versionSize [
	^ 8
]
