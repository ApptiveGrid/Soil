Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'transactionJournals'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visting }
SoilJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ transactionJournals 
		at: anInteger 
		ifAbsentPut: [ self loadTransactionJournalWithId: anInteger ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> buildTransactionJournals [
	| files journals |
	self path exists ifFalse: [ ^ #() ].
	files := self path childrenMatching: '*.journal'.
	journals := Dictionary new.
	(files sorted: [:a :b | a withoutExtension basename asNumber < b withoutExtension basename asNumber]) do: [ :each | | j |
		j := (SoilTransactionJournal new on: each)
			index: each withoutExtension basename asNumber;
			readAll.
		journals at: j index put: j ].
	^ journals
]

{ #category : #copying }
SoilJournal >> copyFrom: start to: end [ 
	^ self class new 
		transactionJournals: (self transactionJournals copyFrom: start to: end)
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
	transactionJournals := Dictionary new
]

{ #category : #'as yet unclassified' }
SoilJournal >> inspectionContent [
	<inspectorPresentationOrder: 0 title: 'transaction journals'>

	^ SpTablePresenter new
		items: (self transactionJournals);
		addColumn: (SpStringTableColumn new 
			title: 'id';
			evaluated: #id;
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
	^ self transactionJournals last index
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
	journal := SoilTransactionJournal new 
		createOn: (self transactionJournalPathFor: anInteger);
		index: anInteger .
	self transactionJournals 
		at: anInteger
		put: journal.
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
	transactionJournals ifEmpty: [ 
		transactionJournals := self buildTransactionJournals ].
	^ transactionJournals "sorted: [ :a :b | a index < b index ]"
]

{ #category : #accessing }
SoilJournal >> transactionJournals: aCollection [ 
	transactionJournals := aCollection
]
