Class {
	#name : #SoilJournalConsistencyVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'databaseVersion',
		'segments'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #initialization }
SoilJournalConsistencyVisitor >> initialize [ 
	super initialize.
	segments := Dictionary new
]

{ #category : #visiting }
SoilJournalConsistencyVisitor >> verifyDatabaseVersion: aSoilTransactionJournal [ 
	| entry |
	"the second last entry is the update of the database version"
	entry := aSoilTransactionJournal entries allButLast last.
	"if we don't have a database version we initialize with the old
	value which includes ANY prior/start value"
	databaseVersion ifNil: [ 
		databaseVersion := entry previousVersion ].
	"after initialization the database version should always be 
	one larger than the one before"
	(entry value = (databaseVersion + 1)) ifFalse: [ 
		Error signal: 'nope' ].
	databaseVersion := entry value
]

{ #category : #visiting }
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
				Error signal: 'nope' ].
			segments 
				at: entry objectId segment
				put: newIndex ]
	
]

{ #category : #visiting }
SoilJournalConsistencyVisitor >> visitJournal: aSoilJournal [ 
	self visitAll: aSoilJournal transactionJournals reverse.
	^ aSoilJournal 
]

{ #category : #visiting }
SoilJournalConsistencyVisitor >> visitTransactionJournal: aSoilTransactionJournal [ 
	self verifyDatabaseVersion: aSoilTransactionJournal.
	self verifyObjectIndexes: aSoilTransactionJournal.
]