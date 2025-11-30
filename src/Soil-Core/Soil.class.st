"
The Soil instance is the main API for your database

To create it:

```
db := Soil path: ‚mydb‘.
db initializeFilesystem.
```

Transactions can be requested from the soil instance:

```
txn := db newTransaction.
txn root: yourModelRoot.
txn commit.
```

this will save the whole object graph pointed to by youModelRoot the database. 

To load the objects back, open another transation and access the root: 

```
txn := db newTransaction.
txn root
```
"
Class {
	#name : #Soil,
	#superclass : #Object,
	#instVars : [
		'path',
		'objectRepository',
		'behaviorRegistry',
		'semaphore',
		'journal',
		'notificationHandler',
		'control',
		'setup',
		'fabric',
		'metadata',
		'transactionManager'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
Soil class >> characterEncoding: aString [ 
	SoilObjectCodec characterEncoding: aString
]

{ #category : #'instance creation' }
Soil class >> createOnPath: aStringOrFileReference [
	^ (self path: aStringOrFileReference)
		initializeFilesystem 
]

{ #category : #accessing }
Soil class >> databaseFormatVersion [ 
	^ 2
]

{ #category : #'instance creation' }
Soil class >> ensureOnPath: aStringOrFileReference [
	| soil |
	soil := self path: aStringOrFileReference.
	^ soil isInitialized  
		ifTrue: [ soil open ]
		ifFalse: [ soil initializeFilesystem ] 
]

{ #category : #'instance creation' }
Soil class >> openOnPath: aStringOrFileReference [
	^ (self path: aStringOrFileReference)
		open
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

{ #category : #accessing }
Soil >> applicationMigrationClass [

	^ self fabric applicationMigrationClass
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

{ #category : #'opening/closing' }
Soil >> basicOpen [
	self isOpen ifTrue: [ self error: 'Database already open' ].
	('open soil database at ', path asString) soilEmit.
	control := SoilControlFile new
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
	transactionManager := SoilTransactionManager new
		soil: self;
		yourself.
	journal := SoilPersistentDatabaseJournal new
		soil: self.
	"journal open might checkpoint so we set the journal 
	instance variable first before calling open"
	journal open.
	notificationHandler := SoilNotificationHandler new
		soil: self.
	metadata := SoilMetadata new 
			soil: self;
			ensurePresent;
			open;
			yourself
	
]

{ #category : #accessing }
Soil >> behaviorRegistry [
	^ behaviorRegistry
]

{ #category : #accessing }
Soil >> checkpoint [ 
	| entry checkpointLSN |
	semaphore critical: [  
		"prepare a consistent setting first "
		entry := SoilCheckpointEntry new
			previousCheckpoint: self control lastCheckpoint.
		"write the checkpoint entry in the journal and get 
		the position of that entry in the file"
		checkpointLSN := self journal writeEntry: entry.
		"set the checkpoint position so it can be read back"
		self control checkpoint: checkpointLSN.
		"finally write all files to disk and sync so that it
		creates a real checkpoint"
		entry commitIn: self.
 ].
	^ entry
]

{ #category : #'opening/closing' }
Soil >> close [
	objectRepository ifNotNil: [ 
		objectRepository close ].
	behaviorRegistry ifNotNil: [ 
		behaviorRegistry close ].
	control ifNotNil: [ 
		control close ].
	journal ifNotNil: [ 
		journal close ].
	metadata ifNotNil: [ 
		metadata close ]
]

{ #category : #accessing }
Soil >> control [

	^ control
]

{ #category : #initialization }
Soil >> critical: aBlock [ 
	semaphore critical: aBlock
]

{ #category : #accessing }
Soil >> defaultFabricClass [ 
	^ SoilFabric 
]

{ #category : #public }
Soil >> destroy [
	self isOpen ifTrue: [ 
		self close ].
	path exists ifFalse: [ ^ self ].
	path children do: #deleteAll.
	path delete
]

{ #category : #accessing }
Soil >> fabric [
	^ fabric ifNil: [ 
		fabric := self defaultFabricClass new ]
]

{ #category : #accessing }
Soil >> fabric: anObject [ 
	fabric := anObject 
]

{ #category : #public }
Soil >> findRecord: aBlock [ 
	| tx |
	tx := self newTransaction.
	^ [ tx findRecord: aBlock ]
		ensure: [ tx abort ]
]

{ #category : #'memory space' }
Soil >> garbageCollect [
	Error signal: 'garbage collect is not ready to be used, yet'.
	SoilGarbageCollectVisitor new 
		soil: self;
		run
]

{ #category : #initialization }
Soil >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
Soil >> initializeFilesystem [
	self isInitialized 
		ifTrue: [ SoilDatabaseAlreadyPresent signal: 'the directory ', path asString, ' already exists' ].
	self path ensureCreateDirectory.
	control := SoilControlFile new
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
	transactionManager := SoilTransactionManager new
		soil: self;
		yourself.
	journal := SoilPersistentDatabaseJournal new
		soil: self;
		initializeFilesystem;
		yourself.
	notificationHandler := SoilNotificationHandler new
		soil: self.
	metadata := SoilMetadata new 
			soil: self;
			initializeFilesystem;
			yourself
]

{ #category : #inspector }
Soil >> inspectionControl: aBuilder [ 
	<inspectorPresentationOrder: 2000 title: 'control'>

	^ self control inspectionControl: aBuilder 
]

{ #category : #inspector }
Soil >> inspectionJournal: aBuilder [
	<inspectorPresentationOrder: 2200 title: 'journal'>
	
	^ self journal inspectionContent: aBuilder 
]

{ #category : #inspector }
Soil >> inspectionMetadata: aBuilder [
	<inspectorPresentationOrder: 2100 title: 'metadata'>

	^ self metadata inspectionMetadata: aBuilder 
]

{ #category : #testing }
Soil >> isInitialized [ 
	^ path exists and: [ path hasChildren ]
]

{ #category : #testing }
Soil >> isOpen [
	^control notNil and: [control isOpen]
]

{ #category : #accessing }
Soil >> journal [
	^ journal 
]

{ #category : #locking }
Soil >> lockDatabaseVersionFor: lockContext [ 
	^ control lockDatabaseVersionFor: lockContext 
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
Soil >> materializerClass [
	^ self fabric materializerClass
]

{ #category : #accessing }
Soil >> metadata [
	^ metadata
]

{ #category : #actions }
Soil >> newApplicationMigration [  
	^ self applicationMigrationClass new 
		soil: self;
		yourself
]

{ #category : #'instance creation' }
Soil >> newMaterializer [
	^ self materializerClass new
		soil: self;
		yourself
]

{ #category : #'instance creation' }
Soil >> newSerializer [
	^ self serializerClass new
		soil: self;
		yourself
]

{ #category : #transactions }
Soil >> newTransaction [
	^ self transactionManager 
		newTransaction: self transactionClass
		readVersion: self control databaseVersion 
]

{ #category : #transactions }
Soil >> newTransaction: aClass [
	| txn |
	txn := aClass new 
		soil: self;
		readVersion: self control databaseVersion;
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
	self basicOpen.
	journal recover
]

{ #category : #'opening/closing' }
Soil >> openLogged [
	self open.
	self metadata updateLastOpened
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
		<< self control databaseVersion printString
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

{ #category : #public }
Soil >> reopen [
	self 
		close;
		open 
]

{ #category : #journal }
Soil >> replayJournal: aSoilJournal [ 
	| journals databaseVersion |
	databaseVersion := self control databaseVersion.
	journals := aSoilJournal 
		transactionJournalsStartingAt: databaseVersion + 1
		do: [:tj | self replayTransactionJournal: tj ].
	self writeEverythingToDisk 
]

{ #category : #journal }
Soil >> replayTransactionJournal: aSoilTransactionJournal [
	| databaseVersion |
	databaseVersion := self control databaseVersion.
	(aSoilTransactionJournal index > databaseVersion) ifTrue: [ 
		aSoilTransactionJournal commitIn: self.
		self journal importTransactionJournal: aSoilTransactionJournal ]
]

{ #category : #'instance creation' }
Soil >> serializerClass [
	^ self fabric serializerClass 
]

{ #category : #accessing }
Soil >> setup [
	^ setup ifNil: [
		setup := SoilSetup new 
			soil: self;
			yourself ] 
]

{ #category : #transactions }
Soil >> transactionClass [
	^ self fabric transactionClass
]

{ #category : #accessing }
Soil >> transactionManager [

	^ transactionManager
]

{ #category : #writing }
Soil >> writeEverythingToDisk [ 
	self behaviorRegistry 
		flush;
		writeContentsToDisk.
	self objectRepository 
		flush;
		writeContentsToDisk.
	self control 
		flush;
		writeContentsToDisk 		
]
