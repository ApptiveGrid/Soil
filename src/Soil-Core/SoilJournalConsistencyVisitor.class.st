Class {
	#name : #SoilJournalConsistencyVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'databaseVersion',
		'segments'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #initialization }
SoilJournalConsistencyVisitor >> initialize [ 
	super initialize.
	segments := Dictionary new
]

{ #category : #api }
SoilJournalConsistencyVisitor >> verifyDatabaseVersion: aSoilTransactionJournal [ 
	| entry |
	"the second last entry is the update of the database version"
	entry := aSoilTransactionJournal entries allButLast last.
	"if we don't have a database version we initialize with the old
	value which includes ANY prior/start value"
	databaseVersion ifNil: [ 
		databaseVersion := entry previousDatabaseVersion ].
	"after initialization the database version should always be 
	one larger than the one before"
	(entry value = (databaseVersion + 1)) ifFalse: [ 
		Error signal: 'Journal consistency check failed: #verifyDatabaseVersion:' ].
	databaseVersion := entry value
]

{ #category : #api }
SoilJournalConsistencyVisitor >> verifyObjectIndexes: aSoilTransactionJournal [ 
	| entries oldIndex newIndex |
	"the second last entry is the update of the database version"
	entries := aSoilTransactionJournal entries select: [:each | each class = SoilNewObjectEntry ].
	(entries sorted: [ :a :b | a objectId index < b objectId index ])
		do: [:entry | 
			newIndex := entry objectId index.
			oldIndex := segments 
				at: entry objectId segment 
				ifAbsentPut: [ entry objectId index - 1].
			(newIndex >= oldIndex) ifFalse: [ 
				Error signal: 'Journal consistency check failed: #verifyObjectIndexes:' ].
			segments 
				at: entry objectId segment
				put: newIndex ]
	
]

{ #category : #visiting }
SoilJournalConsistencyVisitor >> visitTransactionJournal: aSoilTransactionJournal [ 
	self verifyDatabaseVersion: aSoilTransactionJournal.
	self verifyObjectIndexes: aSoilTransactionJournal.
]
