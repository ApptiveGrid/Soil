Class {
	#name : #SoilPersistentDatabaseJournal,
	#superclass : #SoilDatabaseJournal,
	#instVars : [
		'semaphore',
		'currentFragmentFile'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #adding }
SoilPersistentDatabaseJournal >> addTransactionJournal: aTransactionJournal [ 
	semaphore critical: [  
		self verifyNextJournalIndex: aTransactionJournal index.	
		super addTransactionJournal: aTransactionJournal ]

]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> createFragmentFile: filename [
	(self path / filename) ensureCreateFile.
	^ (self openFragmentFile: filename)
		initializeFilesystem;
		yourself
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> currentFragmentFile [
	| currentLSN filename |
	^ currentFragmentFile ifNil: [  
		currentLSN := soil settings checkpoint.
		filename := self filenameFrom: currentLSN fileNumber.
		currentFragmentFile := (currentLSN isInitial) 
			ifTrue: [ self createFragmentFile: filename ]
			ifFalse: [ self openFragmentFile: filename ] ]
]

{ #category : #enumerating }
SoilPersistentDatabaseJournal >> do: aBlock [ 
	semaphore critical: [  
		transactionJournals do: aBlock ]	
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> fileNumberFrom: aString [ 
	^ (ByteArray readHexFrom: aString) asInteger
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> filenameFrom: anInteger [ 
	^ (anInteger printStringBase: 16 length: 10 padded: true) asLowercase 
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> fragmentFileForWriting [
	| segmentFile nextFileNumber |
	segmentFile := self currentFragmentFile.
	^ currentFragmentFile hasSpace 
		ifTrue: [ currentFragmentFile ]
		ifFalse: [ 
			nextFileNumber := (self fileNumberFrom: currentFragmentFile filename).
			currentFragmentFile close.
			currentFragmentFile := self createFragmentFile: (self filenameFrom: nextFileNumber + 1) ]
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> fragmentFiles [
	^ self path children sorted reverse collect: [ :each | SoilJournalFragmentFile path: each ]
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> importEntry: aSoilTransactionJournal [ 
	self writeTransactionJournal: aSoilTransactionJournal.
	super importEntry: aSoilTransactionJournal
]

{ #category : #initialization }
SoilPersistentDatabaseJournal >> initialize [ 
	super initialize.
	transactionJournals := LRUCache new maximumWeight: 20.
	semaphore := Mutex new
]

{ #category : #initialization }
SoilPersistentDatabaseJournal >> initializeFilesystem [
	self path ensureCreateDirectory.

]

{ #category : #tools }
SoilPersistentDatabaseJournal >> inspectionContent [
	<inspectorPresentationOrder: 0 title: 'transaction journals'>

	^ SpTablePresenter new
		items: (self fragmentFiles);
		addColumn: (SpStringTableColumn new 
			title: 'filename';
			evaluated: #filename;
			width: 80);
		addColumn: (SpStringTableColumn new 
			title: #created;
			evaluated: #created;
			width: 50)";
		addColumn: (SpStringTableColumn new 
			title: #firstTransaction;
			evaluated: #firstTransaction;
			width: 50)"
]

{ #category : #'instance creation' }
SoilPersistentDatabaseJournal >> newTransactionJournalForId: anInteger [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: anInteger.
		SoilTransactionJournal new 
			index: anInteger ]
]

{ #category : #'instance creation' }
SoilPersistentDatabaseJournal >> open [ 
	
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> openFragmentFile: filename [ 
	^ (SoilJournalFragmentFile path: self path / filename )
		open;
		yourself
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> path [
	^ soil path / #journal
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> transactionJournalsStartingAt: index do: aBlock [ 
	| fragmentFiles fileIndex |
	fragmentFiles := self fragmentFiles.
	fileIndex := fragmentFiles 
		detectIndex: [ :fragment | fragment firstTransactionId <= index  ]
		ifNone: [ self halt ].
	(fragmentFiles copyFrom: fileIndex to: fragmentFiles size) do: [ :fragmentFile |
		fragmentFile transactionJournals do: [ :transactionJournal |
			aBlock value: transactionJournal ] ].
]

{ #category : #writing }
SoilPersistentDatabaseJournal >> writeEntry: aSoilNewCheckpointEntry [
	"we use the current file to write the end transaction entry in order
	not to split a transaction journal."
	^ currentFragmentFile 
		writeEntry: aSoilNewCheckpointEntry;
		currentLogSequenceNumber
]

{ #category : #writing }
SoilPersistentDatabaseJournal >> writeTransactionJournal: aSoilTransactionJournal [ 
	| file |
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		file := self fragmentFileForWriting.
		aSoilTransactionJournal entries do: [ :entry |
			file writeEntry: entry ] ]
]
