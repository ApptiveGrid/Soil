Class {
	#name : #SoilBackupTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #'as yet unclassified' }
SoilBackupTest >> backupPath [
	^ 'soil-backup'
]

{ #category : #accessing }
SoilBackupTest >> path [ 
	^ 'soil-tests'
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
		soil close ]
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
	soil settings
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
	self assert: backup settings applicationVersion equals: 5]
		ensure: [ backup close ]
	
	
]
