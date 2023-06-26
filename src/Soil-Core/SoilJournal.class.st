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
	transactionJournals addLast: aSoilTransactionJournal 
]

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ self transactionJournals 
		at: anInteger - indexOffset
		ifAbsentPut: [ self loadTransactionJournalWithId: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> buildTransactionJournals [
	| files journals |
	self path exists ifFalse: [ ^ OrderedCollection new ].
	files := self path childrenMatching: '*.journal'.
	journals := OrderedCollection new.
	(files sorted: [:a :b | a withoutExtension basename asNumber < b withoutExtension basename asNumber]) do: [ :each | | jrnl |
		jrnl := (SoilTransactionJournal new on: each)
			index: each withoutExtension basename asNumber;
			readAll.
		journals addLast: jrnl ].
	(journals class = OrderedCollection) ifFalse: [ self halt ]. 
	^ journals 
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
SoilJournal >> importEntry: aSoilTransactionJournal [ 
	| id local |
	id := aSoilTransactionJournal index.
	local := soil journal newTransactionJournalFor: id.
	local addEntries: aSoilTransactionJournal entries.
	local write
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
	^ (self transactionJournals values sorted: [:a :b | a index < b index ]) last index
]

{ #category : #accessing }
SoilJournal >> lastTransactionJournal [
	^ self transactionJournals last
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
SoilJournal >> path [
	^ soil path / #journal
]

{ #category : #accessing }
SoilJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #'as yet unclassified' }
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
				ifFalse: [ Error signal: 'journal index mismatch' ] ]
		ifEmpty: [ ^ self ].
	
]
