Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'behaviorRegistry'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
Soil class >> characterEncoding: aString [ 
	SoilObjectCodec characterEncoding: aString
]

{ #category : #'as yet unclassified' }
Soil class >> inMemory [ 
	^ self new 
		path: FileSystem memory root
]

{ #category : #'instance creation' }
Soil class >> path: aString [ 
	^ self new
		path: aString
]

{ #category : #accessing }
Soil >> behaviorRegistry [
	^ behaviorRegistry
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
		addNewSegment) 
			initializeFilesystem;
			allocateNextIndex.
	behaviorRegistry  
		initializeFilesystem;
		addSpecialObjects
]

{ #category : #'instance creation' }
Soil >> newMaterializer [
	^ SoilMaterializer new 
		soil: self;
		yourself
]

{ #category : #'instance creation' }
Soil >> newSerializer [
	^ SoilSerializer new 
		soil: self
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
		soil: self;
		yourself.
	behaviorRegistry := SoilBehaviorRegistry new
			soil: self;
			open;
			yourself
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
