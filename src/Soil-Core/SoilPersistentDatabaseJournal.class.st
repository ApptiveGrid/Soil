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

{ #category : #writing }
SoilPersistentDatabaseJournal >> appendEntry: aSoilNewCheckpointEntry [
	"append the entry to the current file in order not to split 
	the transaction journal. Remember the postion where the 
	entry is stored and return"
	| entryLSN |
	entryLSN := currentFragmentFile currentLogSequenceNumber.
	currentFragmentFile appendEntry: aSoilNewCheckpointEntry.
	^ entryLSN
		
]

{ #category : #private }
SoilPersistentDatabaseJournal >> createFragmentFile: filename [
	(self path / filename) ensureCreateFile.
	^ (self openFragmentFile: filename)
		initializeFilesystem;
		yourself
]

{ #category : #private }
SoilPersistentDatabaseJournal >> currentFragmentFile [
	| currentLSN filename |
	^ currentFragmentFile ifNil: [  
		currentLSN := soil control lastCheckpoint.
		filename := self filenameFrom: currentLSN fileNumber.
		currentFragmentFile := (currentLSN isInitial) 
			ifTrue: [ self createFragmentFile: filename ]
			ifFalse: [ self openFragmentFile: filename ] ]
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> currentFragmentFile: aSoilJournalFragmentFile [ 
	currentFragmentFile := aSoilJournalFragmentFile
]

{ #category : #'as yet unclassified' }
SoilPersistentDatabaseJournal >> cycleFragmentFile [
	currentFragmentFile := self createFragmentFile: (self filenameFrom: self currentFragmentFile fileNumber + 1)
]

{ #category : #enumerating }
SoilPersistentDatabaseJournal >> do: aBlock [ 
	semaphore critical: [  
		transactionJournals do: aBlock ]	
]

{ #category : #searching }
SoilPersistentDatabaseJournal >> entriesMatching: aBlock [
	^ self fragmentFiles flatCollect: [ :file |
		file entriesMatching: aBlock  ]
]

{ #category : #private }
SoilPersistentDatabaseJournal >> fileNumberFrom: aString [ 
	^ (ByteArray readHexFrom: aString) asInteger
]

{ #category : #private }
SoilPersistentDatabaseJournal >> filenameFrom: anInteger [ 
	^ (anInteger printStringBase: 16 length: 10 padded: true) asLowercase 
]

{ #category : #private }
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
SoilPersistentDatabaseJournal >> fragmentFileWritten: aSoilFragmentFile [ 
	soil setup isFsyncEnabled ifTrue: [  
		aSoilFragmentFile writeContentsToDisk ]
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> fragmentFiles [
	^ self path files sorted reverse collect: [ :each | 
		(SoilJournalFragmentFile path: each)
			databaseJournal: self;
			yourself ]
]

{ #category : #adding }
SoilPersistentDatabaseJournal >> importTransactionJournal: aSoilTransactionJournal [ 
	self writeTransactionJournal: aSoilTransactionJournal.
	self addTransactionJournal: aSoilTransactionJournal
]

{ #category : #initialization }
SoilPersistentDatabaseJournal >> initialize [ 
	super initialize.
	transactionJournals := LRUCache new maximumWeight: 20.
	semaphore := Mutex new
]

{ #category : #initialization }
SoilPersistentDatabaseJournal >> initializeFilesystem [
	self path ensureCreateDirectory
]

{ #category : #inspector }
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

{ #category : #accessing }
SoilPersistentDatabaseJournal >> lastFileNumber [
	^ self fileNumberFrom: self fragmentFiles first basename.
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
	| file lsn |
	self path hasChildren ifFalse: [ 
		file := self currentFragmentFile.
		lsn := self appendEntry: (SoilCheckpointEntry new
			previousCheckpoint: soil control lastCheckpoint).
		soil control checkpoint: lsn ]
	
]

{ #category : #'instance creation' }
SoilPersistentDatabaseJournal >> openFragmentFile: filename [ 
	^ (SoilJournalFragmentFile path: self path / filename )
		databaseJournal: self;
		open;
		yourself
]

{ #category : #'instance creation' }
SoilPersistentDatabaseJournal >> openFragmentFileNumber: anInteger [ 
	^ self openFragmentFile: (self filenameFrom: anInteger)
]

{ #category : #private }
SoilPersistentDatabaseJournal >> openFragmentForLSN: aSoilLogSequenceNumber [ 
	| file |
	file := self openFragmentFileNumber: aSoilLogSequenceNumber fileNumber.
	file position: aSoilLogSequenceNumber fileOffset.
	^ file

]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> path [
	^ soil path / #journal
]

{ #category : #recover }
SoilPersistentDatabaseJournal >> recover [
	SoilDatabaseRecovery new 
		soil: soil;
		journal: self;
		recover 
]

{ #category : #initialization }
SoilPersistentDatabaseJournal >> resetFragmentFile [
	currentFragmentFile := nil
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
	"write entry to fragment file. If the size of the fragment file
	is exceeded a new one will taken to write the entry. Return the 
	position of the entry being written"
	| entryLSN file |
	file := self currentFragmentFile.
	file setToEnd.
	entryLSN := file currentLogSequenceNumber.
	file appendEntry: aSoilNewCheckpointEntry.
	^ entryLSN
		
]

{ #category : #writing }
SoilPersistentDatabaseJournal >> writeTransactionJournal: aSoilTransactionJournal [ 
	| file |
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		file := self fragmentFileForWriting.
		aSoilTransactionJournal entries do: [ :entry |
			file appendEntry: entry ] ]
]
