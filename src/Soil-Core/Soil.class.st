Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'behaviorRegistry',
		'semaphore',
		'settings',
		'journal',
		'notificationHandler'
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

{ #category : #visiting }
Soil >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitSoil: self 
]

{ #category : #visiting }
Soil >> backupTo: aStringOrFileReference [ 
	| backupSoil |
	backupSoil := self class new 
		path: aStringOrFileReference asFileReference;
		destroy;
		initializeFilesystem.
	SoilBackupVisitor new 
		target: backupSoil;
		backup: self.
	backupSoil close
		
]

{ #category : #accessing }
Soil >> behaviorRegistry [
	^ behaviorRegistry
]

{ #category : #'opening/closing' }
Soil >> close [
	objectRepository ifNotNil: [ 
		objectRepository close ].
	behaviorRegistry ifNotNil: [ 
		behaviorRegistry close ].
	settings ifNotNil: [ 
		settings close ]
]

{ #category : #public }
Soil >> createBackupOn: aPath [ 
	self backupTo: aPath
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

{ #category : #public }
Soil >> destroy [
	path exists ifFalse: [ ^ self ].
	path children do: #deleteAll.
	path delete
]

{ #category : #'as yet unclassified' }
Soil >> findRecord: aBlock [ 
	| tx |
	tx := self newTransaction.
	^ [ tx findRecord: aBlock ]
		ensure: [ tx abort ]
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
	journal := SoilPersistentDatabaseJournal new
		soil: self;
		initializeFilesystem;
		yourself.
	notificationHandler := SoilNotificationHandler new
		soil: self
]

{ #category : #inspector }
Soil >> inspectionJournal [
	<inspectorPresentationOrder: 2000 title: 'journal'>
	<ignoreNotImplementedSelectors: #(inspectionContent)>


	^ self journal inspectionContent
]

{ #category : #inspector }
Soil >> inspectionParameters [
	<inspectorPresentationOrder: 2100 title: 'parameters'>

	^ self settings inspectionParameters 
]

{ #category : #accessing }
Soil >> journal [
	^ journal 
]

{ #category : #locking }
Soil >> lockDatabaseVersionFor: lockContext [ 
	^ settings lockDatabaseVersionFor: lockContext 
]

{ #category : #locking }
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
	^ self newTransaction: self transactionClass
]

{ #category : #transactions }
Soil >> newTransaction: aClass [
	| txn |
	txn := aClass new 
		soil: self;
		readVersion: self databaseVersion;
		start;
		yourself.
	notificationHandler transactionCreated: txn.
	^ txn
]

{ #category : #accessing }
Soil >> notificationHandler [ 
	^ notificationHandler
]

{ #category : #accessing }
Soil >> notificationHandler: anObject [

	notificationHandler := anObject
		soil: self;
		yourself
]

{ #category : #accessing }
Soil >> objectRepository [
	^ objectRepository
]

{ #category : #'opening/closing' }
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
	journal := SoilPersistentDatabaseJournal new
		soil: self;
		open;
		yourself.
	notificationHandler := SoilNotificationHandler new
		soil: self
	
]

{ #category : #accessing }
Soil >> path [
	^ path
]

{ #category : #accessing }
Soil >> path: aString [ 
	path := aString asFileReference
]

{ #category : #printing }
Soil >> printOn: aStream [ 
	aStream 
		<< 'Soil ['
		<< self settings databaseVersion printString
		<< '] '
		<< self path pathString
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

{ #category : #journal }
Soil >> replayJournal: aSoilJournal [ 
	| journals databaseVersion |
	databaseVersion := self databaseVersion.
	journals := aSoilJournal 
		transactionJournalsStartingAt: databaseVersion + 1
		do: [:tj | self replayTransactionJournal: tj ]
]

{ #category : #journal }
Soil >> replayTransactionJournal: aSoilTransactionJournal [ 
	| databaseVersion |
	databaseVersion := self databaseVersion.
	"(aSoilTransactionJournal index > databaseVersion) ifTrue: [  "
		"aSoilTransactionJournal asSortedJournal commitIn: self."
		self journal importEntry: aSoilTransactionJournal "] "
]

{ #category : #accessing }
Soil >> settings [

	^ settings
]

{ #category : #accessing }
Soil >> setup [
	^ SoilSetup new 
		soil: self 
]

{ #category : #transactions }
Soil >> transactionClass [
	^ SoilTransaction 
]
