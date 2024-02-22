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

{ #category : #initialization }
SoilDatabaseJournalTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'soil-tests')
		destroy;
		initializeFilesystem
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
	self assert: soil control checkpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 28) 
	
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
		previousCheckpoint: soil control checkpoint).
	soil journal writeTransactionJournal: newJournal.
	soil close.
	soil open.
	self assert: soil control checkpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 61) 
	
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
	self assert: soil control checkpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 28).
	soil close.
	soil open.
	self assert: soil control checkpoint equals: (SoilLogSequenceNumber fileNumber: 0 offset: 61) 
	
	
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
