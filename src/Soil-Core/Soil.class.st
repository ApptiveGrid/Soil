Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'classRegistry'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
Soil class >> characterEncoding: aString [ 
	SoilObjectCodec characterEncoding: aString
]

{ #category : #'instance creation' }
Soil class >> path: aString [ 
	^ self new
		path: aString
]

{ #category : #accessing }
Soil >> classRegistry [
	^ classRegistry ifNil: [ 
		classRegistry := SoilClassRegistry new
			soil: self;
			yourself ]
]

{ #category : #'initialize-release' }
Soil >> close [
	objectRepository ifNotNil: [ 
		objectRepository close ]
]

{ #category : #'as yet unclassified' }
Soil >> destroy [
	path exists ifFalse: [ ^ self ].
	path children do: #deleteAll.
	path delete
]

{ #category : #initialization }
Soil >> initializeFilesystem [
	(path exists and: [ path hasChildren ]) 
		ifTrue: [ SODatabaseAlreadyPresent signal: 'the directory ', path asString, ' already exists' ].
	(objectRepository 
		initializeFilesystem;
		addNewSegment) initializeFilesystem.
	"(SOObjectSegment new 
		objectRepository: objectRepository;
		id: 1) initializeDatabase"
	
]

{ #category : #'instance creation' }
Soil >> newMaterializer [
	^ SoilMaterializer new 
		soil: self;
		yourself
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
