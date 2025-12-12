"
This test class collects related to the ""historu"" features of Soil: being append only, we can ask for old versions for an Object id or create Transactions in the past.
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
