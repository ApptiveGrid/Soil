Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactionJournals',
		'indexOffset'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visting }
SoilJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #adding }
SoilJournal >> addTransactionJournal: aSoilTransactionJournal [ 
	self verifyNextJournalIndex: aSoilTransactionJournal index.	
	transactionJournals addLast: aSoilTransactionJournal.
	[ transactionJournals size <= self numberofJournalsToKeep ]  whileFalse: [ 
		self archiveJournal: transactionJournals removeFirst ].
	indexOffset := transactionJournals first index - 1.

]

{ #category : #'as yet unclassified' }
SoilJournal >> archiveFile: aFileReference [ 
	aFileReference moveTo: (self archivePath / aFileReference basename)
]

{ #category : #adding }
SoilJournal >> archiveJournal: aTransactionJournal [ 
	self archiveFile: (self transactionJournalPathFor: aTransactionJournal index)
]

{ #category : #'as yet unclassified' }
SoilJournal >> archivePath [ 
	^ self path / #archive
]

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ self transactionJournals 
		at: anInteger - indexOffset
		ifAbsentPut: [ self loadTransactionJournalWithId: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> buildTransactionJournals [
	transactionJournals := OrderedCollection new.
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
	self transactionJournals do: aBlock
	
]

{ #category : #'as yet unclassified' }
SoilJournal >> ensureArchivePath [
	self archivePath ensureCreateDirectory 
]

{ #category : #'as yet unclassified' }
SoilJournal >> importEntry: aSoilTransactionJournal [ 
	| id local |
	id := aSoilTransactionJournal index.
	local := self newTransactionJournalFor: id.
	local addEntries: aSoilTransactionJournal entries.
	local write.
	self addTransactionJournal: local
]

{ #category : #initialization }
SoilJournal >> initialize [ 
	super initialize.
	indexOffset := 0
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
SoilJournal >> lastIndex [
	^ self lastTransactionJournal 
		ifNotNil: [ :journal | journal index ]
		ifNil: [ 0 ]
]

{ #category : #accessing }
SoilJournal >> lastTransactionJournal [
	^ self transactionJournals 
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
	| journal |
	self verifyNextJournalIndex: anInteger.
	journal := SoilTransactionJournal new 
		createOn: (self transactionJournalPathFor: anInteger);
		index: anInteger .
	^ journal
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
		self ensureArchivePath.
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
	^ transactionJournals ifNil: [ 
		transactionJournals := self buildTransactionJournals ].
]

{ #category : #accessing }
SoilJournal >> transactionJournals: aCollection [ 
	transactionJournals := aCollection
]

{ #category : #adding }
SoilJournal >> verifyNextJournalIndex: index [ 
	"transaction journals have a strict sequence in the same way the
	databaseVersion has. So we check that this assumption is kept"
	self transactionJournals 
		ifNotEmpty: [ 
			((self lastTransactionJournal index + 1) = index)
				ifFalse: [ 
					Transcript show: ('journal index is not valid: current last index is ', self lastTransactionJournal index printString, ', no index to be added is ', index printString); cr ] ]
		ifEmpty: [ ^ self ].
	
]
