Class {
	#name : #SoilPersistentDatabaseJournal,
	#superclass : #SoilDatabaseJournal,
	#instVars : [
		'semaphore',
		'currentFragmentFile',
		'maxFragmentFiles'
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
SoilPersistentDatabaseJournal >> appendEntry: aSoilJournalEntry [
	"append the entry to the current file in order not to split 
	the transaction journal. Remember the postion where the 
	entry is stored and return"
	| entryLSN |
	entryLSN := currentFragmentFile currentLogSequenceNumber.
	currentFragmentFile appendEntry: aSoilJournalEntry.
	^ entryLSN
		
]

{ #category : #'open/close' }
SoilPersistentDatabaseJournal >> close [
	currentFragmentFile ifNotNil: [
		currentFragmentFile close ]
]

{ #category : #private }
SoilPersistentDatabaseJournal >> createFragmentFile: filename [
	self removeFragmentFiles.
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

{ #category : #fragmentfile }
SoilPersistentDatabaseJournal >> currentFragmentFile: aSoilJournalFragmentFile [ 
	currentFragmentFile := aSoilJournalFragmentFile
]

{ #category : #fragmentfile }
SoilPersistentDatabaseJournal >> cycleFragmentFile [
	| nextFileNumber |
	nextFileNumber := (self fileNumberFrom: currentFragmentFile filename) + 1.
	currentFragmentFile 
		flush;
		writeContentsToDisk;
		close.
	currentFragmentFile := self createFragmentFile: (self filenameFrom: nextFileNumber)
]

{ #category : #enumerating }
SoilPersistentDatabaseJournal >> entriesDo: aBlock [
	self fragmentFiles reverse do: [ :file |
		file entriesDo: aBlock ]
]

{ #category : #queries }
SoilPersistentDatabaseJournal >> entriesMatching: aBlock [
	^ self fragmentFiles flatCollect: [ :file |
		file entriesMatching: aBlock  ]
]

{ #category : #testing }
SoilPersistentDatabaseJournal >> entriesWithObjectId: aSoilObjectId [ 
	^ self objectEntriesSelect: [ :entry | 
		entry includesObjectId: aSoilObjectId ]
]

{ #category : #testing }
SoilPersistentDatabaseJournal >> existsFragmentFileForLSN: aSoilLogSequenceNumber [ 
	| filename |
	filename := self filenameFrom: aSoilLogSequenceNumber fileNumber.
	^ (self path / filename) exists
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
	self currentFragmentFile hasSpace 
		ifFalse: [ self cycleFragmentFile ].
	^ currentFragmentFile
]

{ #category : #fragmentfile }
SoilPersistentDatabaseJournal >> fragmentFileWritten: aSoilFragmentFile [ 
	soil setup isFsyncEnabled ifTrue: [  
		aSoilFragmentFile writeContentsToDisk ]
]

{ #category : #fragmentfile }
SoilPersistentDatabaseJournal >> fragmentFiles [
	^ self sortedFiles collect: [ :each | 
		(SoilJournalFragmentFile path: each)
			databaseJournal: self;
			yourself ]
]

{ #category : #queries }
SoilPersistentDatabaseJournal >> historyOfObjectId: aSoilObjectId [ 
	| history objectEntries transactionStart |
	history := OrderedCollection new.
	objectEntries := OrderedCollection new.
	self entriesDo: [ :entry |
		(entry class = SoilBeginTransactionEntry) ifTrue: [ 
			transactionStart := entry ].
		entry providesObjectIds ifTrue: [ 
			(entry includesObjectId: aSoilObjectId) ifTrue: [ 
				objectEntries add: entry ] ].
		(entry class = SoilCommitTransactionEntry) ifTrue: [ 
			objectEntries ifNotEmpty: [ 
				 history 
					add: transactionStart;
					addAll: objectEntries;
					add: entry ].
				objectEntries removeAll ] ].
	^ history 
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

{ #category : #accessing }
SoilPersistentDatabaseJournal >> maxFragmentFiles [

	^ maxFragmentFiles
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> maxFragmentFiles: anObject [

	maxFragmentFiles := anObject
]

{ #category : #'instance creation' }
SoilPersistentDatabaseJournal >> newTransactionJournalForId: anInteger [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: anInteger.
		SoilTransactionJournal new 
			index: anInteger ]
]

{ #category : #enumerating }
SoilPersistentDatabaseJournal >> objectEntriesDo: aBlock [
	self fragmentFiles reverse do: [ :file |
		file entriesDo: [ :entry | 
			entry providesObjectIds ifTrue: [ 
				 (aBlock value: entry)  ] ] ]
]

{ #category : #queries }
SoilPersistentDatabaseJournal >> objectEntriesSelect: aBlock [
	| entries |
	entries := OrderedCollection new.
	self objectEntriesDo: [ :entry | 
		 (aBlock value: entry) ifTrue: [ 
			entries add: entry ] ].
	^ entries
]

{ #category : #'instance creation' }
SoilPersistentDatabaseJournal >> open [ 
	"if there are no fragment files then we create one with 
	a checkpoint entry to enable consistency with later 
	operations assuming there is a checkpoint"
	self sortedFiles ifEmpty: [ 
		soil checkpoint ]
	
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

{ #category : #private }
SoilPersistentDatabaseJournal >> removeFragmentFiles [
	| files |
	maxFragmentFiles ifNotNil: [ 
		((files := self sortedFiles) size >= maxFragmentFiles) ifTrue: [ 
			(files allButFirst: maxFragmentFiles - 1) do: #delete ] ]
]

{ #category : #initialization }
SoilPersistentDatabaseJournal >> resetFragmentFile [
	currentFragmentFile := nil
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> sortedFiles [
	^ (self path files 
		select: [ :file | 
			"a fragment file is always 10 characters long. 
			40 bit (address space) / 8 (bits in a byte) * 2 (hex characters)"
			(file basename size = 10) ]) sorted reverse
]

{ #category : #accessing }
SoilPersistentDatabaseJournal >> transactionJournalsStartingAt: index do: aBlock [ 
	| fragmentFiles fileIndex |
	fragmentFiles := self fragmentFiles.
	fileIndex := fragmentFiles 
		detectIndex: [ :fragment | fragment firstTransactionId <= index  ]
		ifNone: [ self error: 'fileIndex not found, should not happen' ].
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
	file := self fragmentFileForWriting.
	file setToEnd.
	entryLSN := file currentLogSequenceNumber.
	file appendEntry: aSoilNewCheckpointEntry.
	^ entryLSN
		
]

{ #category : #writing }
SoilPersistentDatabaseJournal >> writeTransactionJournal: aSoilTransactionJournal [ 
	| fragmentFile |
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		fragmentFile := self fragmentFileForWriting.
		fragmentFile appendEntries: aSoilTransactionJournal entries ]
]
