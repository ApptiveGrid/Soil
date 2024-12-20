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
SoilBackupTest >> testBackupTheBackup [
	| tx visitor dict secondBackup txn |
	dict := SoilSkipListDictionary  new
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
SoilBackupTest >> testBackupWithIndex [ 
	| tx backup tx2 dict object |
	tx := soil newTransaction.
	
	dict := SoilSkipListDictionary new 
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
	dict := SoilSkipListDictionary new 
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
SoilBackupTest >> testSimpleBackup [ 
	| tx backup tx2 |
	soil control
		databaseFormatVersion: 1; 
		applicationVersion: 5.
	tx := soil newTransaction.
	tx root: 'simple'.
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
