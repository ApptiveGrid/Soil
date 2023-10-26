Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactionJournals',
		'indexOffset',
		'semaphore',
		'currentSegmentFile'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visting }
SoilJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #adding }
SoilJournal >> addTransactionJournal: aSoilTransactionJournal [ 
	| currentLSN segmentFile |
	semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		transactionJournals at: aSoilTransactionJournal index put: aSoilTransactionJournal  ]

]

{ #category : #queries }
SoilJournal >> allHavingEntriesMatching: aBlock [
	| result |
	result := OrderedCollection new.
	self allTransactionJournalsDo: [ :journal |
		(journal entries anySatisfy: aBlock) ifTrue: [ 
			result add: journal ]].
	^ result
]

{ #category : #queries }
SoilJournal >> allHavingEntriesWithObjectId: aSoilObjectId [
	^ self allHavingEntriesMatching: [ :each | 
		each objectIds includes: aSoilObjectId ].
]

{ #category : #queries }
SoilJournal >> allTransactionJournals [
	| all |
	all := OrderedCollection new.
	self allTransactionJournalsDo: [ :transactionJournal | all add: transactionJournal ].
	^ all
]

{ #category : #enumerating }
SoilJournal >> allTransactionJournalsDo: aBlock [
	self halt.
]

{ #category : #writing }
SoilJournal >> append: aSoilTransactionJournal [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		self segmentFileForWriting writeTransactionLog: aSoilTransactionJournal ]

]

{ #category : #accessing }
SoilJournal >> archiveFile: aFileReference [ 
	self archivePath ensureCreateDirectory.
	aFileReference moveTo: (self archivePath / aFileReference basename)
]

{ #category : #accessing }
SoilJournal >> archivePath [ 
	^ self path / #archive
]

{ #category : #copying }
SoilJournal >> copyFrom: start to: end [ 
	^ self class new 
		soil: soil;
		transactionJournals: (self transactionJournals select: [:each | each index between: start and: end])
]

{ #category : #'as yet unclassified' }
SoilJournal >> createSegmentFile: filename [
	(self path / filename) ensureCreateFile.
	^ (self openSegmentFile: filename)
		initializeFilesystem;
		yourself
]

{ #category : #'as yet unclassified' }
SoilJournal >> currentSegmentFile [
	| currentLSN |
	^ currentSegmentFile ifNil: [  
		currentLSN := soil settings checkpoint.
		currentSegmentFile := (currentLSN isInitial) 
			ifTrue: [ self createSegmentFile: currentLSN filename ]
			ifFalse: [ self openSegmentFile: currentLSN filename ] ]
]

{ #category : #enumerating }
SoilJournal >> do: aBlock [ 
	semaphore critical: [  
		transactionJournals do: aBlock ]	
]

{ #category : #accessing }
SoilJournal >> ensureArchivePath [
	self archivePath ensureCreateDirectory 
]

{ #category : #'as yet unclassified' }
SoilJournal >> importEntry: aSoilTransactionJournal [ 
	| id local |
	id := aSoilTransactionJournal index.
	local := (self newTransactionJournalFor: id)
		addEntries: aSoilTransactionJournal entries;
		write;
		close.
	self addTransactionJournal: local
]

{ #category : #initialization }
SoilJournal >> initialize [ 
	super initialize.
	transactionJournals := LRUCache new maximumWeight: 20.
	semaphore := Semaphore forMutualExclusion.
	indexOffset := 0
]

{ #category : #initialization }
SoilJournal >> initializeFilesystem [
	self path ensureCreateDirectory.

]

{ #category : #tools }
SoilJournal >> inspectionContent [
	<inspectorPresentationOrder: 0 title: 'transaction journals'>

	^ SpTablePresenter new
		items: (self transactionJournals);
		addColumn: (SpStringTableColumn new 
			title: 'index';
			evaluated: #index;
			width: 50);
		addColumn: (SpStringTableColumn new 
			title: #read;
			evaluated: #readVersion;
			width: 50);
		addColumn: (SpStringTableColumn new 
			title: #duration;
			evaluated: #duration;
			width: 50);
		addColumn: (SpStringTableColumn new 
			title: #created;
			evaluated: #createdAt);
		addColumn: (SpStringTableColumn new
			title: #checkpoint;
			evaluated: #checkpointedAt)
]

{ #category : #accessing }
SoilJournal >> lastTransactionJournal [
	^ transactionJournals 
		ifNotEmpty: [ :journals | journals at: journals keys max ]
		ifEmpty: nil
]

{ #category : #'instance creation' }
SoilJournal >> newTransactionJournalFor: anInteger [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: anInteger.
		SoilTransactionJournal new 
			index: anInteger ]
]

{ #category : #'instance creation' }
SoilJournal >> open [ 
	
]

{ #category : #'as yet unclassified' }
SoilJournal >> openSegmentFile: filename [ 
	^ (SoilJournalSegmentFile path: self path / filename )
		open;
		yourself
]

{ #category : #accessing }
SoilJournal >> path [
	^ soil path / #journal
]

{ #category : #'as yet unclassified' }
SoilJournal >> segmentFileAt: logSequenceNumber [
	^ (logSequenceNumber isInitial) 
		ifTrue: [ 
			(SoilJournalSegmentFile path: self path / logSequenceNumber filename)
				create;
				open;
				yourself ] 
		ifFalse: [ 
			self halt. ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> segmentFileForWriting [
	| segmentFile nextFilename |
	segmentFile := self currentSegmentFile.
	^ currentSegmentFile hasSpace 
		ifTrue: [ currentSegmentFile ]
		ifFalse: [ 
			nextFilename := currentSegmentFile currentLogSequenceNumber nextFilename.
			currentSegmentFile close.
			currentSegmentFile := self createSegmentFile: nextFilename ]
]

{ #category : #accessing }
SoilJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilJournal >> transactionJournals [
self halt.
	^ transactionJournals
]

{ #category : #accessing }
SoilJournal >> transactionJournals: aCollection [ 
	transactionJournals := aCollection
]

{ #category : #adding }
SoilJournal >> verifyNextJournalIndex: index [ 
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
SoilJournal >> writeCheckpoint: aSoilNewCheckpointEntry [ 
	^ currentSegmentFile 
		writeCheckpointEntry: aSoilNewCheckpointEntry;
		currentLogSequenceNumber 
]

{ #category : #writing }
SoilJournal >> writeTransactionLog: aSoilTransactionJournal [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		self segmentFileForWriting writeTransactionLog: aSoilTransactionJournal ]

]
