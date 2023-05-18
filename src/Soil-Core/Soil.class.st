Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'behaviorRegistry',
		'semaphore',
		'settings',
		'journal'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
Soil class >> characterEncoding: aString [ 
	SoilObjectCodec characterEncoding: aString
]

{ #category : #accessing }
Soil class >> databaseFormatVersion [ 
	^ 1
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

{ #category : #'as yet unclassified' }
Soil >> buildTransactionJournalPath: anInteger [
	^ self path / #journal / anInteger asString , #journal
]

{ #category : #'initialize-release' }
Soil >> close [
	objectRepository ifNotNil: [ 
		objectRepository close ].
	behaviorRegistry ifNotNil: [ 
		behaviorRegistry close ].
	settings ifNotNil: [ 
		settings close ]
]

{ #category : #initialization }
Soil >> critical: aBlock [ 
	semaphore critical: aBlock
]

{ #category : #accessing }
Soil >> databaseVersion [
	^ settings databaseVersion
]

{ #category : #accessing }
Soil >> databaseVersion: anInteger [ 
	settings databaseVersion: anInteger
]

{ #category : #'as yet unclassified' }
Soil >> destroy [
	path exists ifFalse: [ ^ self ].
	path children do: #deleteAll.
	path delete
]

{ #category : #initialization }
Soil >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
Soil >> initializeFilesystem [
	(path exists and: [ path hasChildren ]) 
		ifTrue: [ SoilDatabaseAlreadyPresent signal: 'the directory ', path asString, ' already exists' ].
	self path ensureCreateDirectory.
	settings := SoilParameterFile new
		soil: self;
		initializeFilesystem;
		yourself.
	objectRepository := SoilObjectRepository new 
		soil: self;
		initializeFilesystem;
		yourself.
	behaviorRegistry := SoilBehaviorRegistry new
			soil: self;
			initializeFilesystem;
			yourself.
]

{ #category : #'as yet unclassified' }
Soil >> inspectionJournal [
	<inspectorPresentationOrder: 40 title: 'journal'>
	<ignoreNotImplementedSelectors: #(inspectionContent)>
	self flag: #TODO.

	^ self journal inspectionContent
]

{ #category : #accessing }
Soil >> journal [
	^ journal ifNil: [ 
		journal := SoilJournal new 
			path: self path / #journal ] 
]

{ #category : #'as yet unclassified' }
Soil >> lockDatabaseVersionFor: lockContext [ 
	^ settings lockDatabaseVersionFor: lockContext 
]

{ #category : #'as yet unclassified' }
Soil >> lockableStream [
	^ self lockableStreamClass new
]

{ #category : #accessing }
Soil >> lockableStreamClass [
	^ SoilLockableStream 
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
	^ SoilTransaction new 
		soil: self;
		readVersion: self databaseVersion;
		yourself
]

{ #category : #'instance creation' }
Soil >> newTransactionJournalFor: anInteger [ 
	^ SoilTransactionJournal new 
		createOn: (self buildTransactionJournalPath: anInteger)
]

{ #category : #accessing }
Soil >> objectRepository [
	^ objectRepository
]

{ #category : #'instance creation' }
Soil >> open [
	('open soil database at ', path asString) soilEmit.
	settings := SoilParameterFile new
		soil: self;
		open.
	objectRepository := SoilObjectRepository new 
		soil: self;
		loadSegments;
		yourself.
	behaviorRegistry := SoilBehaviorRegistry new
			soil: self;
			open;
			yourself.

	
]

{ #category : #accessing }
Soil >> path [
	^ path
]

{ #category : #accessing }
Soil >> path: aString [ 
	path := aString asFileReference
]

{ #category : #refactorings }
Soil >> renameClassNamed: oldName to: newName [
	| transaction behaviorDescription objectId |

	"we load the behaviorDescription of the oldName, change the name and commit"

	transaction := self newTransaction.

	objectId := self behaviorRegistry
		nameAt: oldName
		ifAbsent: [ self error: 'name not found in behavior registry' ].

	behaviorDescription := (transaction objectWithId: objectId) objectId: objectId.
	"the description in the database might not be current, if not, we create a new one later"

	"modify existing description and increment version"
	behaviorDescription initializeFromBehavior: (Smalltalk at: newName).

	self behaviorRegistry
		nameAt: newName
		put: objectId.

	transaction markDirty: behaviorDescription.
	transaction commit
]

{ #category : #accessing }
Soil >> settings [

	^ settings
]
