Class {
	#name : #SoilDatabaseJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'indexOffset',
		'semaphore',
		'currentFragmentFile',
		'cachedTransactionJournals'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #visting }
SoilDatabaseJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #adding }
SoilDatabaseJournal >> addTransactionJournal: aSoilUnitOfWork [ 
	semaphore critical: [  
		self verifyNextJournalIndex: aSoilUnitOfWork index.	
		cachedTransactionJournals at: aSoilUnitOfWork index put: aSoilUnitOfWork  ]

]

{ #category : #accessing }
SoilDatabaseJournal >> cachedTransactionJournals [
	^ cachedTransactionJournals
]

{ #category : #accessing }
SoilDatabaseJournal >> cachedTransactionJournals: aCollection [ 
	cachedTransactionJournals := aCollection
]

{ #category : #copying }
SoilDatabaseJournal >> copyFrom: start to: end [ 
	^ self class new 
		soil: soil;
		cachedTransactionJournals: (self cachedTransactionJournals select: [:each | each index between: start and: end])
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> createFragmentFile: filename [
	(self path / filename) ensureCreateFile.
	^ (self openFragmentFile: filename)
		initializeFilesystem;
		yourself
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> currentFragmentFile [
	| currentLSN filename |
	^ currentFragmentFile ifNil: [  
		currentLSN := soil settings checkpoint.
		filename := self filenameFrom: currentLSN fileNumber.
		currentFragmentFile := (currentLSN isInitial) 
			ifTrue: [ self createFragmentFile: filename ]
			ifFalse: [ self openFragmentFile: filename ] ]
]

{ #category : #enumerating }
SoilDatabaseJournal >> do: aBlock [ 
	semaphore critical: [  
		cachedTransactionJournals do: aBlock ]	
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> fileNumberFrom: aString [ 
	^ (ByteArray readHexFrom: aString) asInteger
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> filenameFrom: anInteger [ 
	^ (anInteger printStringBase: 16 length: 10 padded: true) asLowercase 
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> fragmentFileForWriting [
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
SoilDatabaseJournal >> fragmentFiles [
	^ self path children sorted reverse collect: [ :each | SoilJournalFragmentFile path: each ]
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> importEntry: aSoilTransactionJournal [ 
	| id local |
	id := aSoilTransactionJournal index.
	local := (self newTransactionJournalForId: id)
		addEntries: aSoilTransactionJournal entries;
		write;
		close.
	self addTransactionJournal: local
]

{ #category : #initialization }
SoilDatabaseJournal >> initialize [ 
	super initialize.
	cachedTransactionJournals := LRUCache new maximumWeight: 20.
	semaphore := Mutex new.
	indexOffset := 0
]

{ #category : #initialization }
SoilDatabaseJournal >> initializeFilesystem [
	self path ensureCreateDirectory.

]

{ #category : #tools }
SoilDatabaseJournal >> inspectionContent [
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

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> lastIndex [
	^ self lastTransactionJournal 
		ifNotNil: [ :journal | journal index ]
		ifNil: [ 0 ]
]

{ #category : #accessing }
SoilDatabaseJournal >> lastTransactionJournal [
	^ cachedTransactionJournals 
		ifNotEmpty: [ :journals | journals at: journals keys max ]
		ifEmpty: nil
]

{ #category : #'instance creation' }
SoilDatabaseJournal >> newTransactionJournalForId: anInteger [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: anInteger.
		SoilTransactionJournal new 
			index: anInteger ]
]

{ #category : #'instance creation' }
SoilDatabaseJournal >> open [ 
	
]

{ #category : #'as yet unclassified' }
SoilDatabaseJournal >> openFragmentFile: filename [ 
	^ (SoilJournalFragmentFile path: self path / filename )
		open;
		yourself
]

{ #category : #accessing }
SoilDatabaseJournal >> path [
	^ soil path / #journal
]

{ #category : #accessing }
SoilDatabaseJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #adding }
SoilDatabaseJournal >> verifyNextJournalIndex: index [ 
	"transaction journals have a strict sequence in the same way the
	databaseVersion has. So we check that this assumption is kept"
	"transactionJournals 
		ifNotEmpty: [ 
			((self lastTransactionJournal index + 1) = index)
				ifFalse: [ 
					Transcript show: ('journal index is not valid: current last index is ', self lastTransactionJournal index printString, ', no index to be added is ', index printString); cr ] ]
		ifEmpty: [ ^ self ]"
]

{ #category : #writing }
SoilDatabaseJournal >> writeCheckpointEntry: aSoilNewCheckpointEntry [ 
	^ currentFragmentFile 
		writeCheckpointEntry: aSoilNewCheckpointEntry;
		currentLogSequenceNumber 
]

{ #category : #writing }
SoilDatabaseJournal >> writeTransactionJournal: aSoilUnitOfWork [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilUnitOfWork index.	
		self fragmentFileForWriting writeTransactionJournal: aSoilUnitOfWork ]

]
