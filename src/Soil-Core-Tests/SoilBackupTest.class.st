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
