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
	((self transactionJournalFilesIn: self archivePath) , (self transactionJournalFilesIn: self path))
		do: [ :file | 
			aBlock value: (self readTransactionJournalFile: file) ]
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

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ semaphore critical: [
		transactionJournals 
			at: anInteger - indexOffset
			ifAbsentPut: [ self loadTransactionJournalWithId: anInteger ] ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> buildTransactionJournals [
	self transactionJournalFiles do: [ :each |
		self addTransactionJournal: (
			self readTransactionJournalFile: each) ]
]

{ #category : #copying }
SoilJournal >> copyFrom: start to: end [ 
	^ self class new 
		soil: soil;
		transactionJournals: (self transactionJournals select: [:each | each index between: start and: end])
]

{ #category : #'as yet unclassified' }
SoilJournal >> currentSegmentFile [
	| currentLSN |
	^ currentSegmentFile ifNil: [  
		currentLSN := soil settings checkpoint.
		(currentLSN isInitial) 
			ifTrue: [ (self path / currentLSN filename) ensureCreateFile ].
			
		currentSegmentFile := (SoilJournalSegmentFile path: self path / currentLSN filename)
					open;
					yourself ]
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

{ #category : #accessing }
SoilJournal >> loadTransactionJournalWithId: anInteger [
	^ SoilTransactionJournal new 
		on: self path / anInteger asString , #journal;
		index: anInteger;
		readAll
]

{ #category : #'instance creation' }
SoilJournal >> newTransactionJournalFor: anInteger [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: anInteger.
		SoilTransactionJournal new 
			index: anInteger ]
]

{ #category : #accessing }
SoilJournal >> numberofJournalsToKeep [ 
	^ 20
]

{ #category : #'instance creation' }
SoilJournal >> open [ 
	
]

{ #category : #accessing }
SoilJournal >> path [
	^ soil path / #journal
]

{ #category : #'as yet unclassified' }
SoilJournal >> readTransactionJournalFile: aFileReference [ 
	^ (SoilTransactionJournal new on: aFileReference)
		index: aFileReference withoutExtension basename asNumber;
		readAll;
		close
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

{ #category : #accessing }
SoilJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #queries }
SoilJournal >> transactionJournalFiles [
	| journalFiles |
	journalFiles := self transactionJournalFilesIn: self path. 
	(journalFiles size > self numberofJournalsToKeep) ifTrue: [ 
		(journalFiles copyFrom: 1 to: (journalFiles size - self numberofJournalsToKeep)) do: [ :file |
			self archiveFile: file.
			journalFiles remove: file ] ].
	^ journalFiles 
]

{ #category : #queries }
SoilJournal >> transactionJournalFilesIn: aStringOrFileReference [
	| files journalFiles path |
	path := aStringOrFileReference asFileReference.
	path  exists ifFalse: [ ^ OrderedCollection new ].
	files := path childrenMatching: '*.journal'.
	journalFiles := files sorted: [:a :b | 
		a withoutExtension basename asNumber < b withoutExtension basename asNumber].
	^ journalFiles 
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
		self currentSegmentFile writeTransactionLog: aSoilTransactionJournal ]

]
