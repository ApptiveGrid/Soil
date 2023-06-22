Class {
	#name : #SoilJournalTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'copy'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #'as yet unclassified' }
SoilJournalTest >> fillDatabase [ 
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
SoilJournalTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'soil-tests')
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilJournalTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ].
	copy ifNotNil: [ 
		copy close ]
]

{ #category : #tests }
SoilJournalTest >> testNewRootObject [
	| tx journal |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx checkpoint.
	journal := tx journal.
	self assert: journal size equals: 7.
	self assert: ((journal entryAt: 2) objectId isSameObjectId: (SoilObjectId segment: 1 index: 1)).
	self assert: (journal entryAt: 3) class equals: SoilNewObjectEntry.
	self assert: (journal entryAt: 4) class equals: SoilNewBehaviorEntry.
	self assert: ((journal entryAt: 4) objectId isSameObjectId: (SoilObjectId segment: 0 index: 3)).
	"this should be changed when the behaviors are are in the record"
	"self assert: (journal entryAt: 4) class equals: SoilUpdateSegmentIndexEntry."
	self assert: (journal entryAt: 6) class equals: SoilUpdateDatabaseVersion.
]

{ #category : #tests }
SoilJournalTest >> testNewRootSkipList [
	| tx journal |
	tx := soil newTransaction.
	tx root: (SoilSkipListDictionary new
		maxLevel: 8;
		keySize: 16;
		at: #foo put: #bar;
		yourself).
	tx checkpoint.
	journal := tx journal.
	self assert: journal size equals: 11.
	self assert: (journal anyEntrySatisfy:[:each | each objectId notNil and: [ each objectId isSameObjectId: (SoilObjectId segment: 1 index: 1) ]]).
	self assert: (journal anyEntrySatisfy: [:each | each class = SoilAddKeyEntry ]).
	self assert: (journal entryAt: 7) class equals: SoilNewBehaviorEntry.
	self assert: (journal entryAt: 8) class equals: SoilUpdateSegmentIndexEntry.
	self assert: (journal entryAt: 10) class equals: SoilUpdateDatabaseVersion.
]

{ #category : #tests }
SoilJournalTest >> testReplicationToEmptyDatabase [
	| copy tx |
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
SoilJournalTest >> testReplicationToNonEmptyDatabase [
	| tx |
	self fillDatabase. 
	copy := (Soil path: 'soil-replay')
		destroy;
		initializeFilesystem.
	copy replayJournal: (soil journal copyFrom: 1 to: 3).
	self assert: copy databaseVersion equals: 3.
	self assert: copy objectRepository metaSegment lastObjectIndex equals: 6.
	self assert: copy objectRepository firstSegment lastObjectIndex equals: 4.
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

{ #category : #tests }
SoilJournalTest >> testRootObjectUpdate [
	| tx tx2 journal |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested: #teststring.
	tx2 markDirty: tx2 root.
	tx2 checkpoint.
	journal := tx2 journal.
	self assert: journal size equals: 4.
	self assert: ((journal entryAt: 2) objectId isSameObjectId: (SoilObjectId segment: 1 index: 1)).
	self assert: (journal entryAt: 2) class equals: SoilNewObjectVersionEntry.
	self assert: (journal entryAt: 3) class equals: SoilUpdateDatabaseVersion.
]

{ #category : #tests }
SoilJournalTest >> testRootObjectUpdateClusterObject [
	| tx tx2 journal object |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx commit.
	tx2 := soil newTransaction.
	object := SoilTestNestedObject new.
	tx2 root nested: object.
	tx2 
		markDirty: tx2 root;
		makeRoot: object.
	tx2 checkpoint.
	journal := tx2 journal.
	self assert: journal size equals: 9.
	self assert: (journal entries anySatisfy: [:entry | entry objectId notNil and: [entry objectId isSameObjectId: (SoilObjectId segment: 1 index: 1) ] ]).
	self assert: (journal entries anySatisfy: [:entry | entry class = SoilNewBehaviorEntry ]).
	self assert: (journal entries anySatisfy: [:entry | entry class = SoilUpdateSegmentIndexEntry ]).
	self assert: (journal entryAt: 8) class equals: SoilUpdateDatabaseVersion.

]

{ #category : #tests }
SoilJournalTest >> testRootObjectUpdateClusterPrimitive [
	| tx tx2 journal string |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx commit.
	tx2 := soil newTransaction.
	string := 'teststring'.
	tx2 root nested: string.
	tx2 
		markDirty: tx2 root;
		makeRoot: string.
	tx2 checkpoint.
	journal := tx2 journal.
	self assert: journal size equals: 6.
	self assert: (journal entries anySatisfy: [:entry | entry objectId notNil and: [entry objectId isSameObjectId: (SoilObjectId segment: 1 index: 1)] ]).
	self assert: (journal entryAt: 5) class equals: SoilUpdateDatabaseVersion.

]
