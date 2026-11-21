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
		'readOnly',
		'ownerLockStream',
		'maintenanceAccess'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
Soil class >> characterEncoding: aString [ 
	SoilObjectCodec characterEncoding: aString
]

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

{ #category : #locking }
Soil >> acquiredExclusiveLockOn: aStream [
	"whether this process now holds the lock on the owner file. The one place where the
	file system decides, and its own method because it is what a test replaces: an fcntl
	lock belongs to a process, so a second attempt from this image succeeds and cannot
	show what another process holding it looks like"
	^ aStream wrappedStream lockEntireFileAndBeyond
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
	self emit: 'backing up to ', aStringOrFileReference asString.
	SoilBackupVisitor new 
		target: backupSoil;
		backup: self.
	backupSoil close.
	self emit: 'backup to ', aStringOrFileReference asString, ' finished'
		
]

{ #category : #'opening/closing' }
Soil >> basicOpen [
	self isOpen ifTrue: [ self error: 'Database already open' ].
	"tested before any file is touched: a database marked for maintenance may be in a
	state nobody should read, a half restored copy for instance"
	(self isMarkedForMaintenance and: [ maintenanceAccess ~~ true ]) ifTrue: [
		SoilDatabaseInMaintenance new
			marker: self maintenanceMarkerPath;
			signal ].
	self emit: 'open database at ', path fullName.
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
	notificationHandler := SoilNotificationHandler new
		soil: self.
	metadata := SoilMetadata new 
			soil: self;
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

{ #category : #testing }
Soil >> checkForRecovery [
	"signal SoilDatabaseNeedsRecovery when the journal holds anything a recovery would
	replay, with what it found as the reason. Opened read-only, #open refuses damage only:
	entries past the last checkpoint are read past, because a writer leaves them there for
	a moment on every commit. A reader that must not take such a state for the database -
	a backup that would preserve it is one - asks here, after #open. Reads only, so it can
	be asked of a database on read-only media"

	journal checkForRecovery
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
	"deliberately silent: SoilTransactionManager>>commitTransaction: checkpoints on
	every commit that changed something, so this is the hot path and not the rare
	lifecycle step it looks like from its callers in recovery and on a first open"
	^ entry
]

{ #category : #'opening/closing' }
Soil >> close [
	"said before rather than after, because the interesting case is the one where
	closing does not return"
	self emit: 'closing database'.
	"the claim of #lockExclusive goes last: the process that gets it next must find
	every file closed"
	[ Soil closeAll: { objectRepository . behaviorRegistry . control . journal . metadata } ]
		ensure: [ self unlockExclusive ]
]

{ #category : #gate }
Soil >> closeGate [
	"Refuse new transactions and commits of every other process in this image until
	#openGate, see SoilTransactionManager>>#closeGate. Prefer #gateDo:, which cannot
	forget to open it again."
	self transactionManager closeGate
]

{ #category : #gate }
Soil >> closeGateAndDrainWithin: aDuration [
	"like #closeGate, and wait up to aDuration until no other transaction is open; fails
	with SoilDatabaseBusy, the gate open again, if some still are"
	self transactionManager closeGateAndDrainWithin: aDuration
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

{ #category : #gate }
Soil >> drainedGateDo: aBlock [
	"Run aBlock as the only one in this database: the gate closed and no transaction of
	anybody else open. Fails with SoilDatabaseBusy if there are open transactions, see
	#drainedGateWithin:do: to wait for them."
	^ self drainedGateWithin: 0 seconds do: aBlock
]

{ #category : #gate }
Soil >> drainedGateWithin: aDuration do: aBlock [
	"like #drainedGateDo:, waiting up to aDuration for open transactions to end. The
	process that runs aBlock uses the database as usual, #garbageCollect included"
	self closeGateAndDrainWithin: aDuration.
	^ [ aBlock value ] ensure: [ self openGate ]
]

{ #category : #logging }
Soil >> emit: aString [
	"where this database says what it is doing, and the one place an embedder has
	to fill to collect it elsewhere. Everything in Soil that reports comes through
	here rather than emitting for itself, so overriding is a single decision per
	database instead of one per reporter.

	The default emits a SoilSignal naming the database - which reaches a logger
	that was started for SoilSignal, and nothing else. SoilSignal is a sibling of
	an embedder's own signal class, not an ancestor of it, so an embedder that
	does not override me has to name SoilSignal to its logger.

	Built with #on: rather than #emit:, the way SoilApplicationMigration already
	builds its own: #emit: fills #message and leaves the wrapped object empty, and
	the printing then puts a trailing 'nil' on every line."
	(SoilSignal on: aString)
		databaseName: self name;
		emit
]

{ #category : #locking }
Soil >> exclusiveLockFilePath [
	"the file whose lock says that a process owns this database, and whose contents say
	who that is. See #lockExclusive.

	The lock is an fcntl lock (F_SETLK), and those belong to the process, not to the
	stream: when the owning process closes any other stream on this file, reading it for
	instance, the lock is gone without a word. The owner must not open it a second time,
	neither through another database object on the same path"
	^ path / #'owner.lock'
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
	Quiescent - no concurrent writers during the run. Meta segment untouched.
	The collect runs behind the closed gate: no new transaction, no commit but the
	caller's, see #gateDo:. Transactions that are open stay readable, the collect keeps
	the versions they need. A caller that holds the gate already just runs it."
	self gateDo: [
		SoilGarbageCollectVisitor new
			soil: self;
			run ]
]

{ #category : #gate }
Soil >> gateDo: aBlock [
	"Run aBlock with the gate closed and open it again however aBlock ends. Open
	transactions of others can still read, but not commit. The process that holds the
	gate already just runs aBlock."
	^ self transactionManager gateDo: aBlock
]

{ #category : #testing }
Soil >> holdsExclusiveLock [
	"whether this database object owns its database, see #lockExclusive"
	^ ownerLockStream notNil
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
			yourself.
	"the journal gets its first fragment file and a checkpoint entry right here,
	where writing is the point. A database is complete the moment it is created,
	so no later open has to repair one"
	self checkpoint
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
Soil >> isGateClosed [
	"whether some process of this image has closed the gate, see #closeGate"
	^ self transactionManager isGateClosed
]

{ #category : #testing }
Soil >> isInitialized [ 
	^ path exists and: [ path hasChildren ]
]

{ #category : #testing }
Soil >> isMarkedForMaintenance [
	"whether the maintenance marker is there, see #maintenanceMarkerPath"
	^ self maintenanceMarkerPath exists
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
Soil >> lockExclusive [
	"Claim this database for this process, across processes. See #lockExclusiveAs:, the
	owner written is #ownerDescription"
	self lockExclusiveAs: self ownerDescription
]

{ #category : #locking }
Soil >> lockExclusiveAs: aString [
	"Claim this database for this process, across processes, and write aString into the
	lock file, so that another process that fails to claim it learns who has it - an
	endpoint to forward to, for instance. Fails with SoilDatabaseOwned, carrying what the
	owner wrote. The claim ends with #unlockExclusive or #close, or when the process
	dies: the file lock goes with it. Claiming again while holding it does nothing."
	| lockPath stream owner retries |
	self holdsExclusiveLock ifTrue: [ ^ self ].
	lockPath := self exclusiveLockFilePath.
	lockPath exists ifFalse: [ lockPath ensureCreateFile ].
	stream := lockPath binaryReadWriteStream.
	(self acquiredExclusiveLockOn: stream) ifFalse: [
		"the owner may hold the lock and not have written who it is yet"
		owner := ''.
		retries := 3.
		[ retries >= 0 and: [ owner isEmpty ] ] whileTrue: [
			50 milliSeconds wait.
			stream position: 0.
			owner := stream upToEnd utf8Decoded.
			retries := retries - 1 ].
		stream close.
		^ SoilDatabaseOwned new
			owner: owner;
			signal ].
	stream
		truncate: 0;
		position: 0;
		nextPutAll: aString utf8Encoded;
		flush.
	stream wrappedStream fsync.
	ownerLockStream := stream
]

{ #category : #locking }
Soil >> lockableStream [
	^ self lockableStreamClass new
]

{ #category : #accessing }
Soil >> lockableStreamClass [
	^ SoilLockableStream 
]

{ #category : #maintenance }
Soil >> maintenanceMarkerPath [
	"a file that keeps this database from being opened just by being there. It is set
	from the outside, by touch, while the database is closed, and stays until somebody
	removes it, a crash in between included. #openForMaintenance opens anyway. A
	database that is open already is not affected"
	^ path / #'maintenance.lock'
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
	^ self newSerializer: self serializerClass
]

{ #category : #'instance creation' }
Soil >> newSerializer: aSerializerClass [
	"a serializer of another class than the fabric's, for a caller with its own rules on
	what to write, set up the way every serializer of this database is"
	^ aSerializerClass new
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
Soil >> openForMaintenance [
	"open although the database is marked for maintenance, for the one who does the
	maintenance. Like #open for a database that is not marked"
	maintenanceAccess := true.
	self open
]

{ #category : #gate }
Soil >> openGate [
	"open the gate again after #closeGate. Only the process that closed it can"
	self transactionManager openGate
]

{ #category : #'opening/closing' }
Soil >> openLogged [
	self open.
	self metadata updateLastOpened
]

{ #category : #locking }
Soil >> ownerDescription [
	"what #lockExclusive writes into the lock file. Say something more useful with
	#lockExclusiveAs:"
	^ 'unknown'
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

{ #category : #locking }
Soil >> unlockExclusive [
	"Give up the claim of #lockExclusive. The file is emptied, not deleted: deleted, a
	process that has it open already would lock a file nobody else sees any more, while
	the next one creates a new file and locks that, and two would own the database"
	ownerLockStream ifNil: [ ^ self ].
	[ ownerLockStream
		truncate: 0;
		flush.
	  ownerLockStream wrappedStream unlockEntireFileAndBeyond.
	  ownerLockStream close ]
		ensure: [ ownerLockStream := nil ]
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
