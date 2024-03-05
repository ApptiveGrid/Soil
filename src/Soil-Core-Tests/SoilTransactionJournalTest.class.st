Class {
	#name : #SoilTransactionJournalTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helper }
SoilTransactionJournalTest class >> classUnderTest [ 
	^ SoilPersistentDatabaseJournal 
]

{ #category : #'as yet unclassified' }
SoilTransactionJournalTest >> fillDatabase [ 
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
SoilTransactionJournalTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'soil-tests')
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilTransactionJournalTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilTransactionJournalTest >> testConsistency [
	| txn |
	10 timesRepeat: [ 
		txn := soil newTransaction.
		txn root: Object new.
		txn commit ].
	self 
		shouldnt: [
			SoilJournalConsistencyVisitor new 
				visit: soil ]
		raise: Error
]

{ #category : #tests }
SoilTransactionJournalTest >> testNewRootObject [
	| tx journal |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx basicCommit.
	journal := tx journal.
	self assert: journal size equals: 7.
	self assert: ((journal entryAt: 3) objectId isSameObjectId: (SoilObjectId segment: 1 index: 1)).
	self assert: (journal entryAt: 4) class equals: SoilNewObjectEntry.
	self assert: (journal entryAt: 5) class equals: SoilNewBehaviorEntry.
	self assert: ((journal entryAt: 5) objectId isSameObjectId: (SoilObjectId segment: 0 index: 3)).
	"this should be changed when the behaviors are are in the record"
	"self assert: (journal entryAt: 4) class equals: SoilUpdateSegmentIndexEntry."
	self assert: (journal entryAt: 6) class equals: SoilUpdateDatabaseVersion.
]

{ #category : #tests }
SoilTransactionJournalTest >> testNewRootSkipList [
	| tx journal |
	tx := soil newTransaction.
	tx root: (SoilSkipListDictionary new
		maxLevel: 8;
		keySize: 16;
		yourself).
	tx root at: #foo put: #bar.
	tx basicCommit.
	journal := tx journal.
	self assert: journal size equals: 11.
	self assert: (journal anyEntrySatisfy:[:each | (each isKindOf: SoilNewObjectEntry) and: [ each objectId notNil and: [ each objectId isSameObjectId: (SoilObjectId segment: 1 index: 1) ]]]).
	self assert: (journal anyEntrySatisfy: [:each | each class = SoilAddKeyEntry ]).
	self assert: (journal entryAt: 9) class equals: SoilNewBehaviorEntry.
	self assert: (journal entryAt: 2) class equals: SoilUpdateSegmentIndexEntry.
	self assert: (journal entryAt: 10) class equals: SoilUpdateDatabaseVersion.
]

{ #category : #tests }
SoilTransactionJournalTest >> testRootObjectUpdate [
	| tx tx2 journal |
	tx := soil newTransaction.
	tx root: SoilTestClusterRoot new.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested: #teststring.
	tx2 markDirty: tx2 root.
	tx2 basicCommit.
	journal := tx2 journal.
	self assert: journal size equals: 4.
	self assert: ((journal entryAt: 2) objectId isSameObjectId: (SoilObjectId segment: 1 index: 1)).
	self assert: (journal entryAt: 2) class equals: SoilNewObjectVersionEntry.
	self assert: (journal entryAt: 3) class equals: SoilUpdateDatabaseVersion.
]

{ #category : #tests }
SoilTransactionJournalTest >> testRootObjectUpdateClusterObject [
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
	tx2 basicCommit.
	journal := tx2 journal.
	self assert: journal size equals: 9.
	self assert: (journal entries anySatisfy: [:entry | (entry isKindOf: SoilNewObjectEntry) and: [ entry objectId notNil and: [entry objectId isSameObjectId: (SoilObjectId segment: 1 index: 1) ] ] ]).
	self assert: (journal entries anySatisfy: [:entry | entry class = SoilNewBehaviorEntry ]).
	self assert: (journal entries anySatisfy: [:entry | entry class = SoilUpdateSegmentIndexEntry ]).
	self assert: (journal entryAt: 8) class equals: SoilUpdateDatabaseVersion.

]

{ #category : #tests }
SoilTransactionJournalTest >> testRootObjectUpdateClusterPrimitive [
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
	tx2 basicCommit.
	journal := tx2 journal.
	self assert: journal size equals: 6.
	self assert: (journal entries anySatisfy: [:entry |(entry isKindOf: SoilNewObjectEntry) and: [ entry objectId notNil and: [entry objectId isSameObjectId: (SoilObjectId segment: 1 index: 1)] ] ]).
	self assert: (journal entryAt: 5) class equals: SoilUpdateDatabaseVersion.

]
