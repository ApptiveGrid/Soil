"
This test class collects test related to the ""history"" related features of Soil

Being append only, we can ask for old versions for an Object id or create Transactions in the past.
"
Class {
	#name : #SoilHistoryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #accessing }
SoilHistoryTest >> path [ 
	^ 'soil-tests-history'
]

{ #category : #running }
SoilHistoryTest >> setUp [ 
	super setUp.
	soil := Soil new 
		path: self path;
		destroy;
		initializeFilesystem;
		yourself.
]

{ #category : #running }
SoilHistoryTest >> tearDown [ 
	soil ifNotNil: [ 
		soil close ].
	super tearDown
]

{ #category : #tests }
SoilHistoryTest >> testObjectIDVersions [
	| tx id strings |
	"We store a string and change it two times"
	tx := soil newTransaction.
	tx root: 'String for Testing 1'.
	tx commit.
	
	tx := soil newTransaction.
	tx root at: 20 put: $2.
	tx markDirty: tx root.
	tx commit.
	
		
	tx := soil newTransaction.
	tx root at: 20 put: $3.
	tx markDirty: tx root.
	tx commit.
	
	tx := soil newTransaction.
	"We get the object ID"
	id := tx objectIdOf: tx root.
	"and get all versions of this ID from the database
	API is for now a bit hard to use"
	strings := (tx objectRepository allVersionsOf: id) collect: [ :each | each materializeObjectUsing: tx newMaterializer].
	self assert: strings size equals: 3.
	"take care, lastest version is first"
	self assert: strings first equals: 'String for Testing 3'
]

{ #category : #tests }
SoilHistoryTest >> testObjectIDVersionsViaTransactionInPast [
	| tx history |
	"This test shows that allVersionsOf: on the objectrepository returns the complete history, even though the current transaction might be in the past"
	tx := soil newTransaction.
	tx root: {1}.
	tx commit.

	tx := soil newTransaction.
	tx root at: 1 put: 2.
	tx markDirty: tx root.
	tx commit.

	tx := soil newTransactionForVersion: soil control databaseVersion - 1.
	self assert: tx root equals: {1}.
	
	
	"even though tx is ihe past, #allVersionsOf: returns the complete history"
	history := (tx objectRepository allVersionsOf: (tx objectIdOf: tx root)) collect: [ :each | each materializeObjectUsing: tx newMaterializer].
	self assert: history size equals: 2
]

{ #category : #tests }
SoilHistoryTest >> testTransactionPastVersion [
	| tx |
	"we create a transaction on a past version"
	tx := soil newTransaction.
	tx root: {1}.
	tx commit.

	tx := soil newTransaction.
	tx root at: 1 put: 2.
	tx markDirty: tx root.
	tx commit.

	tx := soil newTransaction.
	self assert: tx root equals: {2}.

	tx := soil newTransactionForVersion: soil control databaseVersion.
	self assert: tx root equals: {2}.

	tx := soil newTransactionForVersion: soil control databaseVersion - 1.
	self assert: tx root equals: {1}
]

{ #category : #tests }
SoilHistoryTest >> testTransactionPastVersionIsReadOnly [
	| tx |
	"we create a transaction on a past version"
	tx := soil newTransaction.
	tx root: {1}.
	tx commit.

	tx := soil newTransaction.
	tx root at: 1 put: 2.
	tx markDirty: tx root.
	tx commit.

	tx := soil newTransactionForVersion: soil control databaseVersion - 1.
	self assert: tx root equals: {1}.
	"But we can not change it as there are newer commits, 
	the database does not support forking the past"
	tx root at: 1 put: 3.
	tx markDirty: tx root.
	self should: [tx commit] raise: SoilObjectHasConcurrentChange
]
