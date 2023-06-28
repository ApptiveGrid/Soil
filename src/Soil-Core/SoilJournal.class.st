Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactionJournals',
		'indexOffset',
		'semaphore'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visting }
SoilJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #adding }
SoilJournal >> addTransactionJournal: aSoilTransactionJournal [ 
	semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		transactionJournals addLast: aSoilTransactionJournal.
		[ transactionJournals size <= self numberofJournalsToKeep ]  whileFalse: [ 
			self archiveJournal: transactionJournals removeFirst ].
		indexOffset := transactionJournals first index - 1 ]

]

{ #category : #'as yet unclassified' }
SoilJournal >> archiveFile: aFileReference [ 
	self archivePath ensureCreateDirectory.
	aFileReference moveTo: (self archivePath / aFileReference basename)
]

{ #category : #adding }
SoilJournal >> archiveJournal: aTransactionJournal [ 
	self ensureArchivePath.
	self archiveFile: (self transactionJournalPathFor: aTransactionJournal index)
]

{ #category : #'as yet unclassified' }
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
	self readTransactionJournalFiles do: [ :each |
		self addTransactionJournal: (
			(SoilTransactionJournal new on: each)
				index: each withoutExtension basename asNumber;
				readAll;
				close) ]
]

{ #category : #copying }
SoilJournal >> copyFrom: start to: end [ 
	^ self class new 
		transactionJournals: (self transactionJournals select: [:each | each index between: start and: end])
]

{ #category : #enumerating }
SoilJournal >> do: aBlock [ 
	semaphore critical: [  
		transactionJournals do: aBlock ]	
]

{ #category : #'as yet unclassified' }
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
	transactionJournals := OrderedCollection new.
	semaphore := Semaphore forMutualExclusion.
	indexOffset := 0
]

{ #category : #initialization }
SoilJournal >> initializeFilesystem [
	self path ensureCreateDirectory.

]

{ #category : #'as yet unclassified' }
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
		ifNotEmpty: [ :journals | journals last ]
		ifEmpty: [ nil ] 
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
			createOn: (self transactionJournalPathFor: anInteger);
			index: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> numberofJournalsToKeep [ 
	^ 20
]

{ #category : #'instance creation' }
SoilJournal >> open [ 
	self buildTransactionJournals 
]

{ #category : #'as yet unclassified' }
SoilJournal >> path [
	^ soil path / #journal
]

{ #category : #'as yet unclassified' }
SoilJournal >> readTransactionJournalFiles [
	| files journalFiles |
	self path exists ifFalse: [ ^ OrderedCollection new ].
	files := self path childrenMatching: '*.journal'.
	journalFiles := files sorted: [:a :b | 
		a withoutExtension basename asNumber < b withoutExtension basename asNumber].
	(journalFiles size > self numberofJournalsToKeep) ifTrue: [ 
		(journalFiles copyFrom: 1 to: (journalFiles size - self numberofJournalsToKeep)) do: [ :file |
			self archiveFile: file.
			journalFiles remove: file ] ].
	^ journalFiles 
]

{ #category : #accessing }
SoilJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilJournal >> transactionJournalPathFor: anInteger [ 
	^ self path / anInteger asString , #journal
]

{ #category : #'as yet unclassified' }
SoilJournal >> transactionJournals [
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
	transactionJournals 
		ifNotEmpty: [ 
			((self lastTransactionJournal index + 1) = index)
				ifFalse: [ 
					Transcript show: ('journal index is not valid: current last index is ', self lastTransactionJournal index printString, ', no index to be added is ', index printString); cr ] ]
		ifEmpty: [ ^ self ]
]
