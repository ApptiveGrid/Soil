Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'segments'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
Soil class >> path: aString [ 
	^ self new
		path: aString
]

{ #category : #'as yet unclassified' }
Soil >> cleanFiles [
	path children do: #deleteAll.
	path delete
]

{ #category : #initialization }
Soil >> initializeDatabase [
	path exists ifTrue: [ SODatabaseAlreadyPresent signal: 'the directory ', path asString, ' already exists' ].
	(SOObjectSegment new 
		soil: self;
		id: 1) initializeDatabase
	
]

{ #category : #'as yet unclassified' }
Soil >> materializationWithId: anInteger ifNone: aBlock [
	| file |
	file := (path / anInteger index asString) asFileReference.
	file exists ifFalse: [ ^ aBlock value ].
	
	^ FLMaterializer newDefault materializeFrom: file binaryReadStream
]

{ #category : #transactions }
Soil >> newTransaction [
	^ SOTransaction new 
		soil: self
]

{ #category : #accessing }
Soil >> path [
	^ path
]

{ #category : #accessing }
Soil >> path: aString [ 
	path := aString asFileReference.
	path ensureCreateDirectory  
]

{ #category : #accessing }
Soil >> segments [ 
	^ segments ifNil: [ 
		segments := self loadSegments ]
]
