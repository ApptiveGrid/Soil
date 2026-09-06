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
		'transactionManager',
		'readOnly'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'opening/closing' }
Soil class >> closeAll: aCollection [
	"Close every element, skipping nils, and answer only once all of them have been
	tried. Closing is release, and stopping at the first failure leaves everything
	behind it open - which is how one file that will not close turns into a handle
	leak, or on Windows into the reason the next open fails.

	The first error is signalled at the end, so a caller still learns the database
	did not close cleanly instead of finding out later. That is a decision, not a
	shortcut, which is why it lives here once instead of in each caller."

	| firstError |
	firstError := nil.
	aCollection do: [ :each |
		each ifNotNil: [
			[ each close ]
				on: Error
				do: [ :error | firstError ifNil: [ firstError := error ] ] ] ].
	firstError ifNotNil: [ firstError signal ]
]

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

{ #category : #testing }
Soil >> canRecover [
	"Whether this image may write to the database in order to recover it. Two
	independent reasons say no: the database was opened read-only, or the medium
	refuses writes."

	^ self readOnly not and: [ self path isWritable ]
]

{ #category : #checking }
Soil >> checkConsistency [
	"Opt-in structural check of this database: index<->heap consistency (I3) and version
	consistency (I6). Raises on the first violation, otherwise returns self. Not part of
	garbageCollect - call it explicitly (e.g. after a GC or in CI)."
	SoilConsistencyVisitor new validate: self.
	SoilCompareVersionsVisitor new validate: self
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
	Soil closeAll: { objectRepository . behaviorRegistry . control . journal . metadata }
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

{ #category : #hooks }
Soil >> fuelAccept: aGeneralMapper [
	"We do not want to serialize a complete database to fuel"
	^ aGeneralMapper visitSubstitution: self by: nil
]

{ #category : #'memory space' }
Soil >> garbageCollect [
	"Offline object-heap garbage collection (Track A): compact each object segment,
	dropping unreachable objects and version-chain entries no open reader still needs.
	Quiescent - no concurrent writers during the run. Meta segment untouched."
	SoilGarbageCollectVisitor new
		soil: self;
		run
]

{ #category : #initialization }
Soil >> initialize [ 
	super initialize.
	readOnly := false.
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
Soil >> migrateApplication [
	"run the application migration up to the version the migration considers
	current. Answering early when there is nothing to do"
	^ self newApplicationMigration migrate
]

{ #category : #migration }
Soil >> migrateDatabaseFormat [
	"open for migration by just resuming the incompatible version 
	exception"
	| needsMigration |
	needsMigration := false.
	[ self basicOpen ]
		on: SoilIncompatibleDatabaseFormat 
		do: [:ex | 
			needsMigration := true. 
			ex resume ].
	needsMigration ifFalse: [ self error: 'database does not need migration' ].
	(SoilDatabaseMigration migratesVersion: self control databaseFormatVersion) new 
		soil: self;
		migrate
]

{ #category : #accessing }
Soil >> name [
	"how this database is addressed: the name of its directory. Not an identity,
	two databases below different roots can carry the same one"
	^ self path basename
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

{ #category : #transactions }
Soil >> newReadOnlyTransaction [
	^ (self transactionManager 
		newTransaction: self transactionClass
		readVersion: self control databaseVersion)
			beReadOnly;
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
Soil >> newTransactionForVersion: version [
	^ self transactionManager 
		newTransaction: self transactionClass
		readVersion: version
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
	aStream << 'Soil ['.
	self isOpen 
		ifTrue: [ self control databaseVersion printOn: aStream ]
		ifFalse: [ aStream << #closed ].
	aStream 
		<< '] '
		<< self path pathString
]

{ #category : #accessing }
Soil >> readOnly [
	"Answer whether this database is open for reading only. Set it before #open."

	^ readOnly
]

{ #category : #accessing }
Soil >> readOnly: aBoolean [
	"Open every file of this database non-writable. Set before #open; changing it
	on an open database does not reopen what is already open."

	readOnly := aBoolean
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

{ #category : #'instance creation' }
Soil >> streamOnPath: aFileReference [
	"Answer the stream every file of this database is opened through. A read-only
	database hands out a plain read stream: the file descriptor is opened
	non-writable, so a write attempt fails at the stream level rather than being
	caught by a Soil-side check. Locking is not needed there - no read path locks."

	^ readOnly
		ifTrue: [ aFileReference asFileReference binaryReadStream ]
		ifFalse: [ self lockableStream initializePath: aFileReference ]
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
