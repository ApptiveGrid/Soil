Class {
	#name : #SoilBackupTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'backupSoil',
		'migrationClass'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilBackupTest >> backupPath [
	^ 'soil-backup'
]

{ #category : #helpers }
SoilBackupTest >> createMigrationClass [
	^ (SoilBaseTestObject << #SOBackupMigrationObject
		layout: FixedLayout;
		slots: { #one }; 
		package: self class package name) install
]

{ #category : #accessing }
SoilBackupTest >> path [ 
	^ 'soil-tests' asFileReference 
]

{ #category : #initialization }
SoilBackupTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilBackupTest >> tearDown [ 
	migrationClass ifNotNil: [ 
		migrationClass removeFromSystem ].
	super tearDown.
	soil ifNotNil: [ 
		soil close ].
	backupSoil ifNotNil: [ 
		backupSoil 
			close;
			destroy ]
]

{ #category : #tests }
SoilBackupTest >> testABackupOpensReadOnly [
	"a backup is checked by opening it for reading, and that open refuses a database
	whose last checkpoint does not read back. The copy's checkpoint has to be one in
	its own journal, not the source's, whose fragments stay behind"
	| tx backup tx2 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: nil).
	tx commit.
	1 to: 5 do: [ :each |
		tx := soil newTransaction.
		tx root nested: each printString.
		tx markDirty: tx root.
		tx commit ].
	soil backupTo: self backupPath.
	backup := Soil new
		path: self backupPath;
		readOnly: true;
		open.
	[ tx2 := backup newTransaction.
	[ self assert: tx2 root nested equals: '5' ] ensure: [ tx2 abort ] ]
		ensure: [ backup close ]
]

{ #category : #tests }
SoilBackupTest >> testABackupKeepsTheIndexAsItWasWhileCommitsGoOn [
	"the backup is a reader like any other while it runs. The index cleaner keeps the
	state of an index page only as long as an open reader needs it, and a backup nobody
	knew about lost an entry removed during the copy. The entry added during the copy
	did not exist at the backup's version and stays out"
	| tx dict visitor tx2 |
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 8;
		maxLevel: 16.
	tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #foo).
	dict at: #bar put: (SoilTestNestedObject new label: #bar).
	tx commit.
	backupSoil := Soil createOnPath: self path, #backup.
	visitor := SoilTestInterleavedBackupVisitor new
		target: backupSoil;
		beforeFirstIndex: [ | during |
			during := soil newTransaction.
			during root removeKey: #bar.
			during root at: #baz put: (SoilTestNestedObject new label: #baz).
			during commit ];
		yourself.
	visitor backup: soil.
	self assert: soil control databaseVersion equals: 2.
	backupSoil close; open.
	tx2 := backupSoil newTransaction.
	[ self assert: (tx2 root at: #foo) label equals: #foo.
	  self assert: (tx2 root at: #bar) label equals: #bar.
	  self assert: (tx2 root at: #baz ifAbsent: [ #absent ]) equals: #absent ]
		ensure: [ tx2 abort ]
]

{ #category : #tests }
SoilBackupTest >> testABackupLeavesOutAClassFirstStoredAfterItsVersion [
	"the behavior registry is read as it is now. A class stored for the first time
	after the backup's version has an entry there whose description did not exist at
	that version, and the backup stopped on it with nil objectId:"
	| tx tx2 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #beforeThePin)).
	tx commit.
	tx := soil newTransaction.
	tx root nested: (SoilTestClusterRoot new nested: #afterThePin).
	tx markDirty: tx root.
	tx commit.
	backupSoil := Soil createOnPath: self path, #backup.
	SoilBackupVisitor new
		target: backupSoil;
		version: 1;
		backup: soil.
	backupSoil close; open.
	tx2 := backupSoil newTransaction.
	[ self assert: tx2 root nested label equals: #beforeThePin ]
		ensure: [ tx2 abort ]
]

{ #category : #tests }
SoilBackupTest >> testABackupGetsThroughMoreCommitsThanTheJournalsKeptInMemory [
	"the backup reads its indexes at its version from the journals of every commit
	since then. With more commits during the copy than journals are kept in memory it
	stopped on KeyNotFound; they are read from the fragment files now"
	| tx dict visitor tx2 |
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 8;
		maxLevel: 16.
	tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #beforeTheBackup).
	tx commit.
	backupSoil := Soil createOnPath: self path, #backup.
	visitor := SoilTestInterleavedBackupVisitor new
		target: backupSoil;
		beforeFirstIndex: [
			| during |
			during := soil newTransaction.
			during root at: #foo put: (SoilTestNestedObject new label: #duringTheBackup).
			during commit.
			1 to: 25 do: [ :each |
				during := soil newTransaction.
				during root at: ('k', each printString) put: (SoilTestNestedObject new label: each).
				during commit ] ];
		yourself.
	visitor backup: soil.
	backupSoil close; open.
	tx2 := backupSoil newTransaction.
	[ self assert: (tx2 root at: #foo) label equals: #beforeTheBackup.
	  self assert: (tx2 root at: #k1 ifAbsent: [ #absent ]) equals: #absent ]
		ensure: [ tx2 abort ]
]

{ #category : #tests }
SoilBackupTest >> testABackupKeepsTheValueAKeyHadAtItsVersion [
	"a key overwritten after the backup's version points at an object that did not
	exist at that version. Leaving such entries out lost the key from the copy,
	although it was there at the version, with the value it had then"
	| tx dict tx2 |
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 8;
		maxLevel: 16.
	tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #beforeThePin).
	tx commit.
	tx := soil newTransaction.
	tx root at: #foo put: (SoilTestNestedObject new label: #afterThePin).
	tx commit.
	backupSoil := Soil createOnPath: self path, #backup.
	SoilBackupVisitor new
		target: backupSoil;
		version: 1;
		backup: soil.
	backupSoil close; open.
	tx2 := backupSoil newTransaction.
	[ self assert: (tx2 root at: #foo) label equals: #beforeThePin ]
		ensure: [ tx2 abort ]
]

{ #category : #tests }
SoilBackupTest >> testBackupCurrentVersion [ 
	| tx tx2 visitor tx3 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne) ).
	tx makeRoot: tx root nested.
	tx commit.
	
	self assert: soil control databaseVersion equals: 1.
	
	tx2 := soil newTransaction.
	tx2 root nested label: #versionTwo.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	
	backupSoil := Soil createOnPath: self path, #backup.
	[ 
	visitor := SoilBackupVisitor new 
		target: backupSoil;
		backup: soil.

	backupSoil close; open.
	
	tx3 := backupSoil newTransaction.
	  self assert: tx3 root nested label equals: #versionTwo ]
		ensure: [ 
			tx3 abort ].
]

{ #category : #tests }
SoilBackupTest >> testBackupInDepthFirstMode [
	"SoilVisitor>>beDepthFirst used to null out `seen`, which processObjectId:
	dereferences unconditionally regardless of traversal mode - depth-first
	backups crashed with a DNU (receiver of #includes: is nil) before the fix
	in SoilVisitor. Nothing in the codebase currently switches a visitor to
	depth-first mode, but the mode must still work correctly."
	| tx tx2 visitor tx3 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne) ).
	tx makeRoot: tx root nested.
	tx commit.

	backupSoil := Soil createOnPath: self path, #backup.
	[ 
	visitor := SoilBackupVisitor new 
		target: backupSoil;
		beDepthFirst;
		backup: soil.
	backupSoil close; open.

	tx3 := backupSoil newTransaction.
	  self assert: tx3 root nested label equals: #versionOne ]
		ensure: [ 
			tx3 abort ].
]

{ #category : #tests }
SoilBackupTest >> testBackupInDepthFirstModePreservesVersionHistory [
	"Depth-first backup writes referenced objects inline while walking, so the
	target byte layout differs from breadth-first; the copied version chain must
	still be logically faithful - every reader version readable as in the source."
	| tx tx2 tx3 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #versionTwo.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx3 := soil newTransaction.
	tx3 root nested label: #versionThree.
	tx3 markDirty: tx3 root nested.
	tx3 commit.
	backupSoil := Soil createOnPath: self path, #backup.
	SoilBackupVisitor new target: backupSoil; beDepthFirst; backup: soil.
	backupSoil close; open.
	1 to: 3 do: [ :v | | srcTx dstTx |
		srcTx := soil newTransactionForVersion: v.
		dstTx := backupSoil newTransactionForVersion: v.
		[ self assert: dstTx root nested label equals: srcTx root nested label ]
			ensure: [ srcTx abort. dstTx abort ] ]
]

{ #category : #tests }
SoilBackupTest >> testBackupOfADatabaseThatOnlyHasItsRoot [
	"the smallest database there is: one commit, nothing in it but the root. Its
	first segment then stands at lastObjectIndex 1, which is exactly the placeholder
	#initializeFilesystem gives a fresh target - and copying that value is a copy,
	not an index that failed to grow. Before this was tolerated, such a database
	could not be backed up at all, which is the state a user database is in between
	being created and being used for the first time."
	| tx tx2 |
	tx := soil newTransaction.
	tx root: SoilPersistentDictionary new.
	tx commit.
	soil backupTo: self backupPath.
	backupSoil := Soil new
		path: self backupPath;
		open.
	tx2 := backupSoil newTransaction.
	self assert: tx2 root class equals: SoilPersistentDictionary
]

{ #category : #tests }
SoilBackupTest >> testBackupOldBehavior [ 
	| tx visitor tx3 object objectId versions object2 |
	migrationClass := self createMigrationClass.
	object := migrationClass new
		instVarNamed: #one put: #onevalue;
		yourself .
	
	tx := soil newTransaction.
	tx makeRoot: object.
	tx root: (Dictionary new 
		at: #oldObject put: object;
		yourself).
	tx commit.
	
	migrationClass addSlot: #two.
	object2 := migrationClass new
		instVarNamed: #two put: #twovalue;
		yourself .
	
	tx := soil newTransaction.
	tx makeRoot: object2.
	tx root at: #newObject put: object2.
	tx markDirty: tx root.
	tx commit.
	
	objectId := soil behaviorRegistry nameAt: #SOBackupMigrationObject ifAbsent: [ Error signal ]. 
	versions := soil objectRepository metaSegment allVersionsAt: objectId index.
	
	self assert: versions size equals: 2.

	backupSoil := Soil createOnPath: self path, #backup.
	
	visitor := SoilBackupVisitor new 
		target: backupSoil;
		backup: soil.

	backupSoil close; open.
	
	tx3 := backupSoil newTransaction.
	self 
		shouldnt: [ (tx3 root at: #oldObject) yourself ]
		raise: Error.
	tx3 abort.
	
	objectId := backupSoil behaviorRegistry nameAt: #SOBackupMigrationObject ifAbsent: [ Error signal ].
	versions := backupSoil objectRepository metaSegment allVersionsAt: objectId index.
	self assert: versions size equals: 2.

]

{ #category : #tests }
SoilBackupTest >> testBackupOldVersion [ 
	| tx tx2 visitor tx3 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne) ).
	tx makeRoot: tx root nested.
	tx commit.
	
	self assert: soil control databaseVersion equals: 1.
	
	tx2 := soil newTransaction.
	tx2 root nested label: #versionTwo.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	
	backupSoil := Soil createOnPath: self path, #backup.
	[ 
	visitor := SoilBackupVisitor new 
		target: backupSoil;
		version: 1;
		backup: soil.

	backupSoil close; open.
	
	tx3 := backupSoil newTransaction.
	  self assert: tx3 root nested label equals: #versionOne ]
		ensure: [ 
			tx3 abort ].
]

{ #category : #tests }
SoilBackupTest >> testBackupPreservesFullVersionHistoryForRegularObjects [
	"A backup must be a faithful copy of the source database - including full MVCC
	history for regular objects (segment 1), not just behavior descriptions
	(segment 0). Before the fix, SoilBackupVisitor only copied the current version
	of regular clusters (via resetPreviousVersion), so an old readVersion became
	unreadable (or silently returned nil/wrong data) after restore."
	| tx tx2 visitor tx3 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne) ).
	tx makeRoot: tx root nested.
	tx commit.

	self assert: soil control databaseVersion equals: 1.

	tx2 := soil newTransaction.
	tx2 root nested label: #versionTwo.
	tx2 markDirty: tx2 root nested.
	tx2 commit.

	backupSoil := Soil createOnPath: self path, #backup.
	visitor := SoilBackupVisitor new
		target: backupSoil;
		backup: soil.
	backupSoil close; open.

	"the backup itself (a normal, unversioned full backup) must still be able to
	answer a historical read for version 1, exactly like the source database can"
	tx3 := backupSoil newTransactionForVersion: 1.
	[ self assert: tx3 root nested label equals: #versionOne ]
		ensure: [ tx3 abort ]
]

{ #category : #tests }
SoilBackupTest >> testBackupTheBackup [
	| tx visitor dict secondBackup txn |
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 10;
		maxLevel: 8;
		yourself.
	tx := soil newTransaction.
	tx root: dict.
	1 to: 100 do: [ :n | dict at: n put: n asString ].
	tx commit.
	
	backupSoil := Soil createOnPath: self path, #backup1.
	visitor := SoilBackupVisitor new 
		target: backupSoil;
		backup: soil.

	backupSoil close; open.
	
	secondBackup := Soil createOnPath: self path, #backup2.
	visitor := SoilBackupVisitor new 
		target: secondBackup;
		backup: backupSoil.
	secondBackup open.

	txn := secondBackup newTransaction.
	self assert: txn root values size equals: 100.
	txn abort.
	
	secondBackup close; destroy
		
]

{ #category : #tests }
SoilBackupTest >> testAnIndexEntryCommittedAfterThePinIsLeftOutOfADatabaseOpenedFromDisk [
	"the same as above, on a database that is opened again, as the metabase opens one
	to copy it. The pages are read back from the files, where a value is a byte array,
	and so are the transaction journals, where the value of an add key entry is a
	SoilObjectId. The two were never equal, so the entry was not taken back from the
	index, and the backup ended in 'nil objectId:' just the same"
	| tx tx2 tx3 visitor dict |
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 8;
		maxLevel: 16.
	tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #beforeThePin).
	tx commit.
	tx2 := soil newTransaction.
	tx2 root at: #bar put: (SoilTestNestedObject new label: #afterThePin).
	tx2 commit.
	soil close.
	soil := Soil new
		path: self path;
		readOnly: true;
		open.
	backupSoil := Soil createOnPath: self path , #backup.
	visitor := SoilBackupVisitor new
		target: backupSoil;
		version: 1;
		yourself.
	visitor backup: soil.
	backupSoil := Soil new
		path: self path , #backup;
		readOnly: true;
		open.
	tx3 := backupSoil newTransaction.
	[ self assert: (tx3 root at: #foo) label equals: #beforeThePin.
	self assert: (tx3 root at: #bar ifAbsent: [ nil ]) isNil ]
		ensure: [ tx3 abort ]
]

{ #category : #tests }
SoilBackupTest >> testAnIndexEntryCommittedAfterThePinIsLeftOut [
	"the records are read at the pinned version, the index as it is now. A commit
	that lands while the backup runs puts an entry into the index whose object has
	no version at the pin - which used to end the backup in 'nil objectId:', every
	night, on a database that is busy for as long as its backup takes"
	| tx tx2 tx3 visitor dict |
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 8;
		maxLevel: 16.
	tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #beforeThePin).
	tx commit.
	tx2 := soil newTransaction.
	tx2 root at: #bar put: (SoilTestNestedObject new label: #afterThePin).
	tx2 commit.
	backupSoil := Soil createOnPath: self path , #backup.
	visitor := SoilBackupVisitor new
		target: backupSoil;
		version: 1;
		yourself.
	visitor backup: soil.
	backupSoil := Soil new
		path: self path , #backup;
		readOnly: true;
		open.
	tx3 := backupSoil newTransaction.
	[ self assert: (tx3 root at: #foo) label equals: #beforeThePin.
	self assert: (tx3 root at: #bar ifAbsent: [ nil ]) isNil ]
		ensure: [ tx3 abort ]
]

{ #category : #tests }
SoilBackupTest >> testBackupWithIndex [ 
	| tx backup tx2 dict object |
	tx := soil newTransaction.
	
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList) 
		keySize: 8;
		maxLevel: 16.
	tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #indexed).
	object := SoilTestClusterRoot new 
		nested: dict.
	tx commit.
	soil backupTo: self backupPath.
	backup := Soil new 
		path: self backupPath;
		open.
	[tx2 := backup newTransaction.
	self assert: (tx2 root at: #foo) label equals: #indexed ]
		ensure: [ backup close ].
	
]

{ #category : #tests }
SoilBackupTest >> testBackupWithIndexRemoval [
	| tx backup tx2 dict object |
	"removed keys in indexes get objectId 0:0. On backup time we only
	need to copy the non-removed"
	tx := soil newTransaction.
	dict := (SoilIndexedDictionary newWithBackend: SoilSkipList)
		keySize: 8;
		maxLevel: 16.
		tx root: dict.
	dict at: #foo put: (SoilTestNestedObject new label: #indexed).
	dict at: #bar put: (SoilTestNestedObject new label: #bar).
	object := SoilTestClusterRoot new 
	nested: dict.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root removeKey: #bar.
	tx2 commit.
	soil backupTo: self backupPath.
	backup := Soil new 
		path: self backupPath;
		open.
	[tx2 := backup newTransaction.
	self assert: (tx2 root at: #foo) label equals: #indexed ]
		ensure: [ backup close ].
	
]

{ #category : #tests }
SoilBackupTest >> testCopyClusterVersionChainRebuildsPreviousVersionPosition [
	"I4: in the target the copied chain is backward-reachable from the current
	version and terminates at previousVersionPosition 0."
	| tx tx2 tx3 objectId versions |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #versionTwo.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx3 := soil newTransaction.
	tx3 root nested label: #versionThree.
	tx3 markDirty: tx3 root nested.
	tx3 commit.
	backupSoil := Soil createOnPath: self path, #backup.
	SoilBackupVisitor new target: backupSoil; backup: soil.
	backupSoil close; open.
	tx := backupSoil newTransaction.
	objectId := tx objectIdOf: tx root nested.
	tx abort.
	versions := (backupSoil objectRepository segmentAt: objectId segment)
		allVersionsAt: objectId index.
	self assert: versions size equals: 3.
	self assert: versions last previousVersionPosition equals: 0.
	self assert: (versions allButLast allSatisfy: [ :each | each previousVersionPosition > 0 ])
]

{ #category : #tests }
SoilBackupTest >> testCopyClusterVersionChainRoundtrip [
	"Roundtrip: a 3-version chain copied into a fresh target must answer at:version:
	for every reader version exactly like the source database."
	| tx tx2 tx3 |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: (SoilTestNestedObject new label: #versionOne)).
	tx makeRoot: tx root nested.
	tx commit.
	tx2 := soil newTransaction.
	tx2 root nested label: #versionTwo.
	tx2 markDirty: tx2 root nested.
	tx2 commit.
	tx3 := soil newTransaction.
	tx3 root nested label: #versionThree.
	tx3 markDirty: tx3 root nested.
	tx3 commit.
	self assert: soil control databaseVersion equals: 3.
	backupSoil := Soil createOnPath: self path, #backup.
	SoilBackupVisitor new target: backupSoil; backup: soil.
	backupSoil close; open.
	1 to: 3 do: [ :v | | srcTx dstTx |
		srcTx := soil newTransactionForVersion: v.
		dstTx := backupSoil newTransactionForVersion: v.
		[ self assert: dstTx root nested label equals: srcTx root nested label ]
			ensure: [ srcTx abort. dstTx abort ] ]
]

{ #category : #tests }
SoilBackupTest >> testSimpleBackup [
	| tx backup tx2 nested |
	soil control
		databaseFormatVersion: Soil databaseFormatVersion; 
		applicationVersion: 5.
	tx := soil newTransaction.
	nested := SoilTestClusterRoot new.
	tx root: (SoilTestGraphRoot new nested: nested).
	tx makeRoot: nested.
	tx commit.
	soil backupTo: self backupPath.
	backup := Soil new 
		path: self backupPath;
		open.
	[tx2 := backup newTransaction.
	self assert: tx2 root equals: tx2 root.
	self assert: backup control applicationVersion equals: 5]
		ensure: [ backup close ]
	
	
]

{ #category : #tests }
SoilBackupTest >> testTheJournalIsNotCopiedAndIsNotMissed [
	"a copy is written by walking the source at a pinned version and writing fresh
	object and index files, so its positions are its own and the source's journal
	entries describe somebody else's. Measured on a database of forty commits, the
	fragments were half of the copy and deleting them from it left every value
	readable.

	Compared rather than counted: whether a freshly initialized database brings a
	first fragment along differs between Soil versions, and what this is about is
	that the source's history does not come with it."
	| tx backup tx2 sizeOf |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: nil).
	tx commit.
	1 to: 5 do: [ :each |
		tx := soil newTransaction.
		tx root nested: each printString.
		tx markDirty: tx root.
		tx commit ].
	soil backupTo: self backupPath.
	sizeOf := [ :directory |
		directory exists
			ifTrue: [ directory files inject: 0 into: [ :sum :each | sum + each size ] ]
			ifFalse: [ 0 ] ].
	self
		assert: (self backupPath asFileReference / #journal) exists
		description: 'the copy writes its own journal from the moment it is opened'.
	self
		assert: (sizeOf value: self backupPath asFileReference / #journal)
			< (sizeOf value: self path / #journal)
		description: 'the source history did not come with it'.
	backup := Soil new
		path: self backupPath;
		open.
	backupSoil := backup.
	tx2 := backup newTransaction.
	[ self assert: tx2 root nested equals: '5' ] ensure: [ tx2 abort ]
]

{ #category : #tests }
SoilBackupTest >> testTheJournalIsCopiedWhenItIsAskedFor [
	"for a copy that is meant to be inspected rather than read"
	| tx visitor backup |
	tx := soil newTransaction.
	tx root: (SoilTestGraphRoot new nested: nil).
	tx commit.
	backup := Soil new
		path: self backupPath;
		destroy;
		initializeFilesystem.
	visitor := SoilBackupVisitor new
		target: backup;
		copyJournal: true;
		yourself.
	visitor backup: soil.
	backupSoil := backup.
	self
		assert: (self backupPath asFileReference / #journal) files notEmpty
		description: 'asked for, the source fragments are there'
]
