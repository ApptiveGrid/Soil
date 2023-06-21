Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'path',
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visting }
SoilJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ SoilTransactionJournal new 
		on: path / anInteger asString , #journal
]

{ #category : #enumerating }
SoilJournal >> do: aBlock [ 
	self transactionJournals do: aBlock
	
]

{ #category : #'as yet unclassified' }
SoilJournal >> importEntry: aSoilTransactionJournal [ 
	| id local |
	id := aSoilTransactionJournal id.
	local := soil newTransactionJournalFor: id.
	local addEntries: aSoilTransactionJournal entries.
	local write
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
SoilJournal >> path: aFileReference [ 
	path := aFileReference 
]

{ #category : #accessing }
SoilJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #'as yet unclassified' }
SoilJournal >> transactionJournals [
	| files |
	path exists ifFalse: [ ^ #() ].
	files := path childrenMatching: '*.journal'.
	^ (files sorted: [:a :b | a withoutExtension basename asNumber > b withoutExtension basename asNumber]) collect: [ :each | 
		(SoilTransactionJournal new on: each)
			readAll ]
]
