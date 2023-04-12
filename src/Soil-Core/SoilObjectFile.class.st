Class {
	#name : #SoilObjectFile,
	#superclass : #SoilSegmentFile,
	#instVars : [
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

{ #category : #initialization }
SoilObjectFile >> initialize [
	super initialize.
	semaphore := Semaphore forMutualExclusion 
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
