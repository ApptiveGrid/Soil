Class {
	#name : #SoilBackupTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'backupSoil'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilBackupTest >> backupPath [
	^ 'soil-backup'
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
