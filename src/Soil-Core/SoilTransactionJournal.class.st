Class {
	#name : #SoilTransactionJournal,
	#superclass : #Object,
	#instVars : [
		'stream',
		'entries'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilTransactionJournal class >> soilTransientInstVars [ 
	^ #( transaction )
]

{ #category : #visiting }
SoilTransactionJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitTransactionJournal: self
]

{ #category : #adding }
SoilTransactionJournal >> addEntries: aCollection [ 
	aCollection do: [ :each | self addEntry: each ]
]

{ #category : #adding }
SoilTransactionJournal >> addEntry: aJournalEntry [
	entries add: aJournalEntry 
]

{ #category : #'as yet unclassified' }
SoilTransactionJournal >> anyEntrySatisfy: aBlock [
	^ entries anySatisfy: aBlock
]

{ #category : #'as yet unclassified' }
SoilTransactionJournal >> checkpoint: aTransaction [
	| entry |
	entry := SoilNewCheckpointEntry new 
		transactionId: aTransaction writeVersion.
	self addEntry: entry.
	entry writeOn: stream.
	stream flush
]

{ #category : #'initialize-release' }
SoilTransactionJournal >> close [ 
	stream ifNotNil: [ stream close ]
]

{ #category : #committing }
SoilTransactionJournal >> commitIn: aTransaction [ 
	entries do: [ :each | each commitIn: aTransaction ]
]

{ #category : #'instance creation' }
SoilTransactionJournal >> create [
	stream := self path 
		deleteIfAbsent: []; 
		ensureCreateFile;
		binaryWriteStream 
]

{ #category : #'instance creation' }
SoilTransactionJournal >> createOn: aFileReference [
	stream := aFileReference 
		deleteIfAbsent: []; 
		ensureCreateFile;
		binaryWriteStream 
]

{ #category : #accessing }
SoilTransactionJournal >> entries [
	^ entries
]

{ #category : #accessing }
SoilTransactionJournal >> entryAt: anInteger [ 
	^ entries at: anInteger 
]

{ #category : #accessing }
SoilTransactionJournal >> id [
	^ (stream wrappedStream name asFileReference withoutExtension basename) asInteger
]

{ #category : #initialization }
SoilTransactionJournal >> initialize [ 
	super initialize.
	entries := OrderedCollection new
]

{ #category : #'as yet unclassified' }
SoilTransactionJournal >> inspectionEntries [
	<inspectorPresentationOrder: 0 title: 'journal entries'>

	^ SpTablePresenter new
		items: entries;
		addColumn: (SpCompositeTableColumn new
			title: '#';
			width: 30;
			addColumn: (SpStringTableColumn evaluated: [:each | entries indexOf: each ]));
		addColumn: (SpCompositeTableColumn new
			title: 'Name';
			addColumn: (SpStringTableColumn evaluated: [:each | each class name ]));
		addColumn: (SpCompositeTableColumn new
			title: 'container';
			addColumn: (SpStringTableColumn evaluated: [:each | each container ]));
		addColumn: (SpCompositeTableColumn new
			title: 'address';
			addColumn: (SpStringTableColumn evaluated: [:each | each address ]));
		addColumn: (SpCompositeTableColumn new
			title: 'value';
			addColumn: (SpStringTableColumn evaluated: [:each | each value ]));
		addColumn: (SpCompositeTableColumn new
			title: 'oldValue';
			addColumn: (SpStringTableColumn evaluated: [:each | each oldValue ]))
]

{ #category : #'instance creation' }
SoilTransactionJournal >> on: aFileReference [
	stream := aFileReference binaryReadStream 
]

{ #category : #accessing }
SoilTransactionJournal >> path: aFileReference [ 
	self shouldBeImplemented.
]

{ #category : #'as yet unclassified' }
SoilTransactionJournal >> readAll [
	| pageCode entry |
	[ stream atEnd ] whileFalse: [ 
		pageCode := stream next asInteger.
		entry := (SoilJournalEntry withTypeCode: pageCode) new.
		entries add: (entry readFrom: stream) ].
]

{ #category : #accessing }
SoilTransactionJournal >> size [ 
	^ entries size
]

{ #category : #writing }
SoilTransactionJournal >> write [ 
	entries do: [ :each | each writeOn: stream ].
	stream 
		flush
]
