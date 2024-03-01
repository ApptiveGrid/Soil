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
		'serializerClass',
		'materializerClass',
		'control',
		'setup'
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

{ #category : #'instance creation' }
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

{ #category : #'opening/closing' }
Soil >> basicOpen [
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
	journal := SoilPersistentDatabaseJournal new
		soil: self;
		open;
		yourself.
	notificationHandler := SoilNotificationHandler new
		soil: self
	
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
	control ifNotNil: [ 
		control close ]
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
Soil >> databaseVersion [
	^ control databaseVersion
]

{ #category : #accessing }
Soil >> databaseVersion: anInteger [ 
	control databaseVersion: anInteger
]

{ #category : #'instance creation' }
Soil >> defaultMaterializerClass [
	^ SoilMaterializer
]

{ #category : #'instance creation' }
Soil >> defaultSerializerClass [
	^ SoilSerializer
]

{ #category : #public }
Soil >> destroy [
	path exists ifFalse: [ ^ self ].
	path children do: #deleteAll.
	path delete
]

{ #category : #public }
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
	journal := SoilPersistentDatabaseJournal new
		soil: self;
		initializeFilesystem;
		yourself.
	notificationHandler := SoilNotificationHandler new
		soil: self
]

{ #category : #inspector }
Soil >> inspectionControl [
	<inspectorPresentationOrder: 2100 title: 'control'>

	^ self control inspectionControl 
]

{ #category : #inspector }
Soil >> inspectionJournal [
	<inspectorPresentationOrder: 2000 title: 'journal'>
	
	^ self journal inspectionContent
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
	^ materializerClass ifNil: [ self defaultMaterializerClass ]
]

{ #category : #accessing }
Soil >> materializerClass: anObject [

	materializerClass := anObject
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
	self basicOpen.
	journal recover
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
	(aSoilTransactionJournal index > databaseVersion) ifTrue: [ 
		aSoilTransactionJournal asSortedJournal commitIn: self.
		self journal importTransactionJournal: aSoilTransactionJournal ]
]

{ #category : #'instance creation' }
Soil >> serializerClass [
	^ serializerClass ifNil: [ self defaultSerializerClass ]
]

{ #category : #accessing }
Soil >> serializerClass: anObject [

	serializerClass := anObject
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
	^ SoilTransaction 
]
