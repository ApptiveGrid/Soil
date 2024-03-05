Class {
	#name : #SoilDatabaseJournalTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'copy'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helper }
SoilDatabaseJournalTest class >> classUnderTest [ 
	^ SoilPersistentDatabaseJournal 
]

{ #category : #running }
SoilDatabaseJournalTest >> addDictionaryRoot [ 
	| tx |
	tx := soil newTransaction.
	tx root: Dictionary new.
	tx commit
]

{ #category : #running }
SoilDatabaseJournalTest >> fillDatabase [ 
	| tx dict |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx commit.
	tx := soil newTransaction.
	dict := SoilSkipListDictionary new 
		maxLevel: 8;
		keySize: 10.
	tx makeRoot: dict.
	tx root nested: dict.
	tx markDirty: tx root.
	tx commit.
	tx := soil newTransaction.
	tx root nested 
		at: #foo put: (SoilTestNestedObject new 
			label: #foolabel);
		at: #bar put: tx root.
	tx markDirty: tx root nested.
	tx commit.
	tx := soil newTransaction.
	tx root nested removeKey: #bar.	
	tx commit.
	tx := soil newTransaction.
	(tx root nested at: #foo) label: #newLabel.	
	tx markDirty: (tx root nested at: #foo).
	tx commit.
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> modifyDictionaryRootEntry [
	| txn record newRecord |
	txn := soil newTransaction.
	record := (txn recordWithId: SoilObjectId root)
		transaction: txn;
		materializeObject;
		yourself.
	record object at: #foo put: #bar.
	newRecord := record asNewClusterVersion
		version: 1;
		serializeObject;
		yourself.
	^ newRecord asJournalEntry first
				transactionId: 1;
				yourself
]

{ #category : #initialization }
SoilDatabaseJournalTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'soil-tests')
		destroy;
		initializeFilesystem;
		close;
		open
]

{ #category : #running }
SoilDatabaseJournalTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ].
	copy ifNotNil: [ 
		copy close ]
]

{ #category : #tests }
SoilDatabaseJournalTest >> testRecoverWithAtEnd [
	soil close.
	soil open.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 28) 
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> testRecoverWithIncompleteTransactionJournal [	
	| newJournal |
	self addDictionaryRoot.
	newJournal := SoilTransactionJournal new.
	newJournal 
		addEntry: (SoilBeginTransactionEntry new
			readVersion: 0; 
			transactionId: 1;
			createdAt: DateAndTime now);
		addEntry: self modifyDictionaryRootEntry.
	soil journal writeTransactionJournal: newJournal.
	soil journal currentFragmentFile stream 
		nextPutAll: #( 1 2 3 4 );
		flush.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 86).
	soil close.
	soil open.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 1 offset: 28) 
	
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> testRecoverWithJournalAndCheckpoint [
	| newJournal |
	
	newJournal := SoilTransactionJournal new.
	newJournal addEntry: (SoilBeginTransactionEntry new
		readVersion: 0; 
		transactionId: 1;
		createdAt: DateAndTime now).
	newJournal addEntry: (SoilCommitTransactionEntry new 
		transactionId: 1;
		committedAt: DateAndTime now;
		yourself).
	newJournal addEntry: (SoilCheckpointEntry new
		previousCheckpoint: soil control lastCheckpoint).
	soil journal writeTransactionJournal: newJournal.
	soil close.
	soil open.
	"we have now two entries checkpoint at the end but that is to be expected"
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 72) 
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> testRecoverWithRemainingBytes [
	
	soil journal currentFragmentFile stream 
		nextPutAll: #( 1 2 3 4 );
		flush.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 28).
	soil close.
	soil open.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 1 offset: 28) 
	
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> testRecoverWithRemainingJournal [
	| newJournal |
	
	newJournal := SoilTransactionJournal new.
	newJournal addEntry: (SoilBeginTransactionEntry new
		readVersion: 0; 
		transactionId: 1;
		createdAt: DateAndTime now).
	newJournal addEntry: (SoilCommitTransactionEntry new 
		transactionId: 1;
		committedAt: DateAndTime now;
		yourself).
	soil journal writeTransactionJournal: newJournal.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 28).
	soil close.
	soil open.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 61) 
	
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> testRecoverWithRemainingJournalAndBytes [
	| newJournal txn |
	self addDictionaryRoot.
	newJournal := SoilTransactionJournal new.
	newJournal 
		addEntry: (SoilBeginTransactionEntry new
			readVersion: 0; 
			transactionId: 1;
			createdAt: DateAndTime now);
		addEntry: self modifyDictionaryRootEntry;
		addEntry: (SoilCommitTransactionEntry new 
			transactionId: 1;
			committedAt: DateAndTime now;
			yourself).
	soil journal writeTransactionJournal: newJournal.
	"put bogus bytes after the journal"
	soil journal currentFragmentFile stream 
		nextPutAll: #( 1 2 3 4 );
		flush.
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 86).
	soil close.
	soil open.
	"the fragment file should have advanced to a new file so the truncated bytes are the rest of
	the old file which can be skipped in future reads"
	self assert: soil control lastCheckpoint equals: (SoilLogSequenceNumber fileNumber: 1 offset: 28).
	"the change of the replayed transaction should be visible now"
	txn := soil newTransaction. 
	[ self assert: (txn root at: #foo) equals: #bar  ]
		ensure: [ txn abort ]
	
	
]

{ #category : #tests }
SoilDatabaseJournalTest >> testReplicationToEmptyDatabase [
	| tx |
	self fillDatabase. 
	copy := (Soil path: 'soil-replay')
		destroy;
		initializeFilesystem.
	copy replayJournal: soil journal.
	tx := copy newTransaction.
	self assert: soil databaseVersion equals: copy databaseVersion.
	self assert: soil objectRepository metaSegment lastObjectIndex equals: copy objectRepository metaSegment lastObjectIndex.
	self assert: soil objectRepository firstSegment lastObjectIndex equals: copy objectRepository firstSegment lastObjectIndex.
	self assert: soil journal lastIndex equals: copy journal lastIndex
]

{ #category : #tests }
SoilDatabaseJournalTest >> testReplicationToNonEmptyDatabase [
	| tx |
	self fillDatabase. 
	copy := (Soil path: 'soil-replay')
		destroy;
		initializeFilesystem.
	copy replayJournal: (soil journal copyFrom: 1 to: 3).
	self assert: copy databaseVersion equals: 3.
	self assert: copy objectRepository metaSegment lastObjectIndex equals: 5.
	self assert: copy objectRepository firstSegment lastObjectIndex equals: 3.
	copy replayJournal: soil journal.
	self assert: soil journal lastIndex equals: copy journal lastIndex.
	self assert: soil databaseVersion equals: copy databaseVersion.
	self assert: soil objectRepository metaSegment lastObjectIndex equals: copy objectRepository metaSegment lastObjectIndex.
	self assert: soil objectRepository firstSegment lastObjectIndex equals: copy objectRepository firstSegment lastObjectIndex.
	self assert: soil journal lastIndex equals: copy journal lastIndex.
	tx := soil newTransaction.
	self assert: (tx root nested at: #foo) label equals: #newLabel.	
	tx abort.
]
