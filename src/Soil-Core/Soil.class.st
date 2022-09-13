Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository'
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

{ #category : #accessing }
Soil >> defaultSegment [
	^ SOObjectSegment new
		id: 1;
		soil: self
]

{ #category : #initialization }
Soil >> initializeDatabase [
	path exists ifTrue: [ SODatabaseAlreadyPresent signal: 'the directory ', path asString, ' already exists' ].
	(SOObjectSegment new 
		objectRepository: objectRepository;
		id: 1) initializeDatabase
	
]

{ #category : #'as yet unclassified' }
Soil >> materializationWithId: objectId ifNone: aBlock [
	| indexFile objectFile position bytes |
	bytes := self objectRepository at: objectId.
	
	^ FLMaterializer materializeFrom: bytes readStream
]

{ #category : #transactions }
Soil >> newTransaction [
	^ SOTransaction new 
		soil: self
]

{ #category : #accessing }
Soil >> objectRepository [
	^ objectRepository
]

{ #category : #'instance creation' }
Soil >> open [
	objectRepository := SOObjectRepository new 
		soil: self
]

{ #category : #accessing }
Soil >> path [
	^ path
]

{ #category : #accessing }
Soil >> path: aString [ 
	path := aString asFileReference.
	self open
]

{ #category : #accessing }
Soil >> serializer [
	^ FLSerializer new
		when: [ :o | o isRoot ] substituteBy: [ :a |self halt]
]
