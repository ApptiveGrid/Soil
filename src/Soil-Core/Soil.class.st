Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'behaviorRegistry',
		'parameters'
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

{ #category : #accessing }
Soil >> databaseVersion [
	^ parameters databaseVersion
]

{ #category : #accessing }
Soil >> databaseVersion: anInteger [
	parameters databaseVersion: anInteger
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
	self path ensureCreateDirectory.
	parameters := SoilParameterFile new
		soil: self;
		initializeFilesystem;
		yourself.
	objectRepository := SOObjectRepository new
		soil: self;
		initializeFilesystem;
		yourself.
	behaviorRegistry := SoilBehaviorRegistry new
			soil: self;
			initializeFilesystem;
			yourself
]

{ #category : #'as yet unclassified' }
Soil >> lockDatabaseVersionFor: lockContext [
	^ parameters lockDatabaseVersionFor: lockContext
]

{ #category : #'as yet unclassified' }
Soil >> lockableStream [
	^ self lockableStreamClass new
]

{ #category : #accessing }
Soil >> lockableStreamClass [
	^ SOLockableStream
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
		soil: self;
		readVersion: self databaseVersion;
		yourself
]

{ #category : #accessing }
Soil >> objectRepository [
	^ objectRepository
]

{ #category : #'instance creation' }
Soil >> open [
	parameters := SoilParameterFile new
		soil: self;
		open.
	objectRepository := SOObjectRepository new
		soil: self;
		loadSegments;
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
	path := aString asFileReference
]
