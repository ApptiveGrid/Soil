Class {
	#name : #SoilTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'idMap',
		'objectMap',
		'readVersion',
		'writeVersion',
		'behaviorDescriptions',
		'locks',
		'lastObjectIndexes',
		'journal',
		'createdAt',
		'indexUpdatesToCommit',
		'commitStrategy',
		'changedBehaviorDescriptions'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #aborting }
SoilTransaction >> abort [
	soil ifNil: [ ^ self  ].
	self transactionManager abortTransaction: self
]

{ #category : #accessing }
SoilTransaction >> acquireLocksAndDetectWriteSkew [
	self resetLastObjectIndexes.
	"first iterate over all records to acquire locks and check for concurrent 
	writes. Might be changed later to rely on the journal in case of accident"
	commitStrategy records do: [ :record |
		record initializeObjectIdsIn: self.
		"check if the version we've read is still actual. Another transaction could have
		committed since we last read. Checking for the position in the index is sufficient
		as each version relates to a unique position"
		self addLock: record lockIndex.
		record validateReadVersion ].
	"idMap is keyed by objectIds which could have changed by now so we rehash in order
	not to miss lookups"
	idMap rehash.
]

{ #category : #api }
SoilTransaction >> addClusterObject: anObject [ 
	| objectId |
	objectMap at: anObject ifPresent: [ :record |  ^ record objectId ].
	objectId := self newObjectId .
	self 
		atObjectId: objectId
		putObject: anObject.
	^ objectId

]

{ #category : #adding }
SoilTransaction >> addIndexUpdate: anIndex [
	indexUpdatesToCommit add: anIndex
]

{ #category : #adding }
SoilTransaction >> addJournalEntry: anEntry [ 
	self addJournalEntry: anEntry head: false
]

{ #category : #adding }
SoilTransaction >> addJournalEntry: anEntry head: aBoolean [
	aBoolean 
		ifTrue: [ self journal addEntryToHead: anEntry  ]
		ifFalse: [ self journal addEntryToTail: anEntry ]
]

{ #category : #adding }
SoilTransaction >> addLock: aLock [ 
	locks add: aLock
]

{ #category : #adding }
SoilTransaction >> addObjectToBeCommited: anObject [ 
	| record |
	record := objectMap 
		at: anObject theNonSoilProxy
		ifAbsent: [ SoilNotAClusterRoot signal: 'cannot mark dirty a non-existing root' ].
	commitStrategy addRecord: record 
]

{ #category : #accessing }
SoilTransaction >> atObjectId: objectId putObject: anObject [
	| record |
	record := SoilNewClusterVersion new
		object: anObject;
		objectId: objectId;
		transaction: self.
	idMap at: objectId put: record.
	objectMap at: anObject put: record.
	commitStrategy addRecord: record
]

{ #category : #aborting }
SoilTransaction >> basicAbort [
	commitStrategy reset.
	behaviorDescriptions := nil.
	idMap := nil.
	objectMap := nil
]

{ #category : #accessing }
SoilTransaction >> basicCommit [
	"serialize objects and collect all to be written records. This can be done without 
	resources that need locking. This reduces time needed for locking"
	commitStrategy prepareCommit.
	"if there are no records to commit we can just return and don't allocate any
	resources"
	self needsCommit ifFalse: [ 
		soil notificationHandler transactionCommitted: self.
		self updateBehaviorHistoryCachesAfterCommit.
		^ self ].
	"only one transactions is allowed at a time. We use the critical block of the database
	to avoid parallel committing"
	soil critical: [ 
	"enter lock phase. Acquire lock on global databaseVersion which centrally locks
	the database for commiting until this checkpoint is done. The ensure block is needed
	to be sure to release all locks at the end."
		[ 
		"lock global database version and create a version for new modification"
		writeVersion := self buildWriteVersion.
		"lock all records in the segment and check indexes for out of date versions"
		self acquireLocksAndDetectWriteSkew.
		"lastObjectIndexes contains the highest allocated index number per segment. We
		lock all positions in order to update the index numbers in the database."
		lastObjectIndexes keysDo: [ :segment |
			self addLock: (segment lockAppendingFor: self) ].
		"convert the records into journal entries, write the journal to disk and then
		execute the journal on the database"
		journal := self buildJournal.
		journal validateIn: self.
		soil journal writeTransactionJournal: journal.
		journal commitIn: soil.
		soil journal addTransactionJournal: journal ]
				ensure: [self releaseLocks ] ].
	soil notificationHandler transactionCommitted: self.
	"any new behavior versions committed above are now durable - extend
	SoilBehaviorRegistrys cached version histories to match"
	self updateBehaviorHistoryCachesAfterCommit
]

{ #category : #accessing }
SoilTransaction >> beAutoMigrating [ 
	commitStrategy beAutoMigrating 
]

{ #category : #'public accessing' }
SoilTransaction >> beAutomaticWriteTracking [
	commitStrategy := SoilAutomaticTrackingStrategy new
		transaction: self;
		yourself 
]

{ #category : #'public accessing' }
SoilTransaction >> beManualWriteTracking [
	commitStrategy := SoilManualTrackingStrategy new
		transaction: self;
		yourself 
]

{ #category : #'public accessing' }
SoilTransaction >> beReadOnly [ 
	commitStrategy := SoilReadOnlyStrategy new
		transaction: self;
		yourself 
]

{ #category : #public }
SoilTransaction >> behaviorDescriptionFor: aClass [
	| behaviorDescription objectId |
	"locally created behavior descriptions are always current and can
	be returned immediately"
	behaviorDescriptions
		at: aClass soilBehaviorIdentifier
		ifPresent: [ :description | ^ description ].
	"if we find the behaviorIdentifier in the registry and it is 
	current we can return it"
	objectId := soil behaviorRegistry
		nameAt: aClass soilBehaviorIdentifier
		ifAbsent: nil.

	objectId ifNotNil: [ 
		behaviorDescription := (objectId index == 2)
			ifTrue: [ ^ SoilBehaviorDescription meta ]
			ifFalse: [ (self objectWithId: objectId) 
				ifNotNil: [ :object | object objectId: objectId ]
				ifNil: [ Error signal: ('could not find object with ', objectId asString, ' for class ', aClass name, ' in transaction ', self printString) ] ].
		"the description in the database might not be current, if not, we create a new one later"
		behaviorDescription isCurrent 
			ifTrue: [ ^ behaviorDescription ] ].

	"behaviorDescription is only set if we've found an old version"
	behaviorDescription 
		ifNotNil: [ 
			"modify existing description and increment version"
			behaviorDescription 
				initializeFromBehavior: aClass;
				incrementVersion.
			"add a new version record to keep the previous position"
			self makeNewVersion: behaviorDescription.
			"remember this behavior so its new, now-persisted version can be appended to
			SoilBehaviorRegistrys cached version history once this transaction commits
			(see SoilTransaction>>updateBehaviorHistoryCachesAfterCommit)"
			changedBehaviorDescriptions add: behaviorDescription ]
		ifNil: [  
			"this is a new description with version 1"
			behaviorDescription := (SoilBehaviorDescription for: aClass)
				beFirstVersion;
				objectId: self newMetaObjectId.
			self atObjectId: behaviorDescription objectId putObject: behaviorDescription. ].
	behaviorDescriptions
		at: aClass soilBehaviorIdentifier
		put: behaviorDescription.
	^ behaviorDescription
]

{ #category : #api }
SoilTransaction >> behaviorDescriptionWithObjectId: objectId andVersion: version [ 
	idMap 
		at: objectId
		ifPresent: [ :record | 
			(record object version = version)
				ifTrue: [ ^ record object ] ].

	^ self behaviorRegistry behaviorDescriptionWithIndex: objectId index andVersion: version transaction: self
]

{ #category : #accessing }
SoilTransaction >> behaviorRegistry [
	^ soil behaviorRegistry 
]

{ #category : #api }
SoilTransaction >> behaviorVersionsUpTo: aSOBehaviorDescription [ 
	^ self behaviorRegistry 
		behaviorVersionsUpTo: aSOBehaviorDescription
		transaction: self .
	
]

{ #category : #accessing }
SoilTransaction >> buildJournal [
	self journal index: writeVersion.
	"add entries for updating the last index of each modified 
	segment"
	lastObjectIndexes keysAndValuesDo: [ :segment :index |
		journal addEntry: (SoilUpdateSegmentIndexEntry new 
			segment: segment;
			index: index value) ].
	"create entries for all new objects and new object versions"
	commitStrategy records do: [ :record |
		record version: writeVersion.
		journal addEntries: record asJournalEntry ].
	"for all new objects with a new behavior we create an entry to
	add the behavior"
	behaviorDescriptions do: [ :description |
		journal addEntry: (SoilNewBehaviorEntry new 
			identifier: description value behaviorIdentifier;
			objectId: description objectId) ].
	"update the global database version"
	journal addEntry: (SoilUpdateDatabaseVersion new 
		databaseVersion: writeVersion;
		previousDatabaseVersion: readVersion).
	journal addEntry: (SoilCommitTransactionEntry new 
		committedAt: DateAndTime now;
		yourself).
	^ journal
]

{ #category : #accessing }
SoilTransaction >> buildWriteVersion [
	"first we lock the database version so it cannot be modified while we are 
	checkpointing"
	self addLock: (soil lockDatabaseVersionFor: self).
	"Now the version is locked. We can read it again to have the real version and
	increment"
	^ soil control databaseVersion + 1 
]

{ #category : #accessing }
SoilTransaction >> commit [
	self transactionManager commitTransaction: self 
]

{ #category : #actions }
SoilTransaction >> commitAndContinue [
	self transactionManager commitAndContinueTransaction: self 
]

{ #category : #accessing }
SoilTransaction >> commitStrategy [
	^ commitStrategy
]

{ #category : #actions }
SoilTransaction >> continue [
	commitStrategy hasRecords ifFalse: [ ^ self ].
	commitStrategy records do: [ :record | | persistentRecord |
		persistentRecord := record asPersistentClusterVersion.
		objectMap at: record object put: persistentRecord.
		idMap at: record objectId put: persistentRecord ].
	commitStrategy reset.
	self flag: #todo.
	"we change the readVersion here so we can read back the 
	objects we've just changed. But we do not check if all the
	not-updated objects are still at a current state. So there 
	can be objects that are out-of-date. Reading will read old 
	state and writing to them will make the transaction commit 
	fail because then there is a concurrent modification"
	readVersion := writeVersion.
	writeVersion := nil.
	journal := nil.
	lastObjectIndexes := nil
]

{ #category : #accessing }
SoilTransaction >> database [
	^ soil
]

{ #category : #accessing }
SoilTransaction >> errorOnWriteAttempts [ 
	commitStrategy errorOnWriteAttempts 
]

{ #category : #'api - debugging' }
SoilTransaction >> findObject: aBlock [ 
	"scan all records in the database where the materialized object matches 
	the condition in aBlock. Return the object of the record instead"
	^ (self findRecord: [:record | aBlock value: record materializeObject ]) object
]

{ #category : #api }
SoilTransaction >> findRecord: aBlock [ 
	"scan all connected records in the database until one matches 
	the condition in aBlock"
	 ^ (SoilFindRecordsVisitor new  
		returnFirst;
		find: aBlock 
		in: self;
		records)
			ifNotEmpty: [ :records | records first ] 
			ifEmpty: [ nil ] 
]

{ #category : #'api - debugging' }
SoilTransaction >> findRecords: aBlock [ 
	"scan all connected records in the database until one matches 
	the condition in aBlock."
	 ^ SoilFindRecordsVisitor new 
		find: aBlock 
		in: self;
		records
]

{ #category : #testing }
SoilTransaction >> hasChanges [ 
	"before committing a transaction collects changes in the journal. While committing
	recordsToCommit gets populated. We want to ask for modifications regardless of the 
	phase of the transaction so we check both"
	^ commitStrategy hasChanges or: [ 
			self hasJournalEntries ]
]

{ #category : #testing }
SoilTransaction >> hasJournalEntries [ 
	
	^ journal notNil and: [ journal size > 1 ]
]

{ #category : #accessing }
SoilTransaction >> ignoreWriteAttempts [ 
	commitStrategy ignoreWriteAttempts 
]

{ #category : #initialization }
SoilTransaction >> initialize [ 
	super initialize.
	idMap := Dictionary new.
	objectMap := IdentityDictionary new.
	behaviorDescriptions := Dictionary new.
	locks := OrderedCollection new.
	indexUpdatesToCommit := OrderedCollection new.
	changedBehaviorDescriptions := OrderedCollection new.
	self beAutomaticWriteTracking
]

{ #category : #api }
SoilTransaction >> initializeObjectId: anObjectId [
	| segment assoc |
	anObjectId isInitialized ifTrue: [ SoilObjectIdAlreadyInitialized signal: 'object id is already initialized: ', anObjectId asString ].
	segment := self objectRepository segmentAt: anObjectId segment.
	"maintain last object indexes per segment"
	assoc := lastObjectIndexes 
		at: segment 
		ifAbsentPut: [ 
			self addLock: (segment lockLastObjectIndexFor: self).
			segment lastObjectIndex -> segment lastObjectIndex ].
	"we use an association here to keep the version read from database
	as well as the new version"
	assoc value: assoc value + 1.
	anObjectId index: assoc value
]

{ #category : #testing }
SoilTransaction >> isAborted [
	^ idMap isNil and: [objectMap isNil]
]

{ #category : #testing }
SoilTransaction >> isAutoMigrating [
	^ commitStrategy isAutoMigrating 
]

{ #category : #testing }
SoilTransaction >> isPersistent: anObject [
	^ self isRoot: anObject
]

{ #category : #testing }
SoilTransaction >> isReadOnly [ 
	^ self isWritable not
]

{ #category : #testing }
SoilTransaction >> isRoot: anObject [
	self flag: #todo.
	"this is surely not true but a shortcut for now"
	^ (objectMap 
		at: anObject theNonSoilProxy 
		ifAbsent: nil) notNil
]

{ #category : #testing }
SoilTransaction >> isWritable [
	^ commitStrategy isWritable
]

{ #category : #accessing }
SoilTransaction >> journal [ 
	^ journal ifNil: [ 
		journal := self newJournal ]
]

{ #category : #api }
SoilTransaction >> lockObjectId: aSOObjectId [ 
	^ self objectRepository lockObjectId: aSOObjectId for: self
]

{ #category : #public }
SoilTransaction >> makeNewVersion: classDescription [
	| record |
	record := objectMap at: classDescription.
	commitStrategy addRecord: record asNewClusterVersion
]

{ #category : #api }
SoilTransaction >> makeRoot: anObject [ 
	| objectId |
	self isWritable ifFalse: [ 
		SoilWriteOnReadOnlyTransaction new 
			object: anObject;
			signal ].
	objectId := self addClusterObject: anObject theNonSoilProxy.
	anObject soilClusterRootIn: self.
	^ objectId

]

{ #category : #public }
SoilTransaction >> markDirty: anObject [

	commitStrategy markDirty: anObject 
]

{ #category : #api }
SoilTransaction >> materializeRecord: record [
	| materializer |
	materializer := self newMaterializer.
	record
		transaction: self;
		materializeObjectUsing: materializer.
	
	commitStrategy 
		recordMaterialized: record 
		materializer: materializer.
		
	^ record 
]

{ #category : #'as yet unclassified' }
SoilTransaction >> needsCommit [ 

	^ self isWritable and: [ self hasChanges ]
]

{ #category : #'instance creation' }
SoilTransaction >> newClusterVersion [
	^ SoilNewClusterVersion new
		changed: true; 
		transaction: self.
]

{ #category : #accessing }
SoilTransaction >> newJournal [
	journal := SoilTransactionJournal new.
	journal addEntry: (SoilBeginTransactionEntry new
		readVersion: readVersion; 
		createdAt: createdAt).
	^ journal

]

{ #category : #'instance creation' }
SoilTransaction >> newMaterializer [
	^ soil newMaterializer 
		transaction: self;
		yourself
]

{ #category : #'instance creation' }
SoilTransaction >> newMetaObjectId [
	^ self objectRepository newMetaObjectId
]

{ #category : #'instance creation' }
SoilTransaction >> newObjectId [ 
	^ self objectRepository newObjectId
]

{ #category : #'instance creation' }
SoilTransaction >> newPersistentClusterVersion [
	^ SoilPersistentClusterVersion new
		transaction: self.
]

{ #category : #accessing }
SoilTransaction >> newSerializer [
	^ soil newSerializer
		transaction: self;
		yourself

]

{ #category : #accessing }
SoilTransaction >> objectAt: anObjectId ifAbsent: aBlock [
	idMap ifNil: [ 
		SoilTransactionAlreadyAborted signal: 'this transaction has already been aborted' ].

	idMap 
		at: anObjectId 
		ifPresent: [ :record | ^ record object ]
		ifAbsent: aBlock 
]

{ #category : #api }
SoilTransaction >> objectIdOf: anObject [ 
	^ anObject isSoilProxy
		ifTrue: [ anObject objectId ]
		ifFalse: [ (objectMap at: anObject) objectId ].
	
]

{ #category : #accessing }
SoilTransaction >> objectIndex [
	^ objectMap
]

{ #category : #accessing }
SoilTransaction >> objectMap [
	^ objectMap
]

{ #category : #api }
SoilTransaction >> objectRepository [ 
	^ soil objectRepository
]

{ #category : #api }
SoilTransaction >> objectWithId: objectId [
	idMap ifNil: [ 
		SoilTransactionAlreadyAborted signal: 'this transaction has already been aborted' ].

	idMap 
		at: objectId
		ifPresent: [ :record | ^ record object ].

	^ (self recordWithId: objectId)
		ifNotNil: [ :record |
			self materializeRecord: record.
			idMap at: objectId put: record.
			objectMap at: record object put: record.
			record object
				soilLoadedIn: self;
				yourself ]
]

{ #category : #printing }
SoilTransaction >> printOn: aStream [ 
	aStream << 'transaction read: ' << readVersion asString << ', write: ' << writeVersion asString
]

{ #category : #api }
SoilTransaction >> proxyForObjectId: aSOObjectId [ 
	^ aSOObjectId asSoilObjectProxy 
		transaction: self
]

{ #category : #accessing }
SoilTransaction >> readVersion [
	^ readVersion
]

{ #category : #accessing }
SoilTransaction >> readVersion: anInteger [ 
	readVersion := anInteger
]

{ #category : #api }
SoilTransaction >> recordWithId: objectId [
	(objectId isInitialized) ifFalse: [ SoilIndexOutOfRange signal: 'object id ', objectId printString, ' needs index greater than zero' ].
	^ self objectRepository 
		at: objectId 
		version: readVersion
]

{ #category : #accessing }
SoilTransaction >> registerRecord: record [
	record objectId ifNil: [ Error signal: 'register record needs an objectId' ].
	record object ifNil: [ Error signal: 'register record needs an object' ].
	idMap at: record objectId put: record.
	objectMap at: record object put: record
]

{ #category : #api }
SoilTransaction >> releaseLocks [
	locks copy do: [ :lock | self removeLock: lock ]
]

{ #category : #adding }
SoilTransaction >> removeLock: aLock [ 
	aLock release.
	locks remove: aLock
]

{ #category : #accessing }
SoilTransaction >> resetLastObjectIndexes [
	lastObjectIndexes := Dictionary new
]

{ #category : #accessing }
SoilTransaction >> root [

	^ self objectWithId: SoilObjectId root
]

{ #category : #accessing }
SoilTransaction >> root: anObject [
	self 
		atObjectId: SoilObjectId root 
		putObject: anObject.
	anObject soilClusterRootIn: self
]

{ #category : #accessing }
SoilTransaction >> segmentAt: anInteger [ 
	^ self objectRepository segmentAt: anInteger 
]

{ #category : #initialization }
SoilTransaction >> setWriteVersion: anInteger [ 
	"This is only used for replaying a journal and such 
	where a transaction does not get set up properly"
	(anInteger > readVersion) ifFalse: [ 
		SoilInvalidWriteVersion signal: 'write version ', anInteger asString , ' is not greater than read version ', readVersion asString ]. 
	writeVersion := anInteger 
]

{ #category : #accessing }
SoilTransaction >> soil [
	^ soil
]

{ #category : #accessing }
SoilTransaction >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilTransaction >> start [
	createdAt := DateAndTime now
]

{ #category : #accessing }
SoilTransaction >> transactionManager [ 
	^ soil transactionManager
]

{ #category : #public }
SoilTransaction >> updateBehaviorHistoryCachesAfterCommit [
	"After a successful commit, any new behavior version created during this transaction
	is now durably persisted - extend SoilBehaviorRegistrys cached version history for
	each of them in place (O(1) append, no reload of the whole history from disk).
	Must only be called after a successful commit, never on abort - an aborted
	transaction must not be able to change shared, cross-transaction state."
	changedBehaviorDescriptions isEmpty ifTrue: [ ^ self ].
	changedBehaviorDescriptions do: [ :description |
		soil behaviorRegistry
			appendCommittedVersion: description
			forIndex: description objectId index ].
	changedBehaviorDescriptions := OrderedCollection new
]

{ #category : #accessing }
SoilTransaction >> writeVersion [
	^ writeVersion
]
