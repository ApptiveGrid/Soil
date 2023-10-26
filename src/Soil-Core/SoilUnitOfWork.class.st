Class {
	#name : #SoilUnitOfWork,
	#superclass : #Object,
	#instVars : [
		'index',
		'entries'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilUnitOfWork class >> readFrom: aStream [ 
	^ self new 
		readFrom: aStream;
		yourself
]

{ #category : #accessing }
SoilUnitOfWork class >> soilTransientInstVars [ 
	^ #( transaction )
]

{ #category : #visiting }
SoilUnitOfWork >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitUnitOfWork: self
]

{ #category : #adding }
SoilUnitOfWork >> addEntries: aCollection [ 
	aCollection do: [ :each | self addEntry: each ]
]

{ #category : #adding }
SoilUnitOfWork >> addEntry: aJournalEntry [
	entries add: aJournalEntry 
]

{ #category : #'as yet unclassified' }
SoilUnitOfWork >> anyEntrySatisfy: aBlock [
	^ entries anySatisfy: aBlock
]

{ #category : #converting }
SoilUnitOfWork >> asSortedJournal [
| first last middle sorted |
	"Current treatment of new values keeps values in a dictionary loosing order. This 
	helper method sorts the dictionary keys for index access in a way that the appending
	page case can be used"
	first := OrderedCollection new.
	last := OrderedCollection new.
	middle := OrderedCollection new.
	entries do: [ :entry |
		({ SoilNewTransactionEntry . SoilNewBehaviorEntry . SoilNewObjectEntry . SoilNewObjectVersionEntry . SoilNewSkipListIndexEntry . SoilNewBTreeListIndexEntry } includes:  entry class) ifTrue: [ 
			first add: entry ]  .
		({ SoilUpdateDatabaseVersion . SoilUpdateSegmentIndexEntry . SoilNewCheckpointEntry } includes:  entry class) ifTrue: [ 
			last add: entry ].
		({ SoilAddKeyEntry  . SoilRemoveKeyEntry } includes:  entry class) ifTrue: [ 
			middle add: entry ] ].
	middle := middle sorted: [ :a :b | a key < b key ].
	sorted := first, middle, last.
	(sorted size = entries size) ifFalse: [ self halt ].
	^ self copy 
		entries: sorted;
		yourself
]

{ #category : #'as yet unclassified' }
SoilUnitOfWork >> checkpoint: aTransaction [
	| entry |
	entry := SoilNewCheckpointEntry new 
		transactionId: aTransaction writeVersion.
	self addEntry: entry.
	entry commitIn: aTransaction.
	^ entry
]

{ #category : #'as yet unclassified' }
SoilUnitOfWork >> checkpointedAt [
	^ entries last checkpointedAt 
]

{ #category : #committing }
SoilUnitOfWork >> commitIn: aTransaction [ 
	entries do: [ :each | each commitIn: aTransaction ]
]

{ #category : #accessing }
SoilUnitOfWork >> createdAt [
	^ entries first createdAt
]

{ #category : #accessing }
SoilUnitOfWork >> duration [
	^ (self checkpointedAt - self createdAt) asMilliSeconds  
]

{ #category : #accessing }
SoilUnitOfWork >> entries [
	^ entries
]

{ #category : #accessing }
SoilUnitOfWork >> entries: aCollection [ 
	entries := aCollection
]

{ #category : #accessing }
SoilUnitOfWork >> entryAt: anInteger [ 
	^ entries at: anInteger 
]

{ #category : #accessing }
SoilUnitOfWork >> index [

	^ index
]

{ #category : #accessing }
SoilUnitOfWork >> index: anObject [

	index := anObject
]

{ #category : #initialization }
SoilUnitOfWork >> initialize [ 
	super initialize.
	entries := OrderedCollection new
]

{ #category : #tools }
SoilUnitOfWork >> inspectionEntries [
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

{ #category : #accessing }
SoilUnitOfWork >> path: aFileReference [ 
	self shouldBeImplemented.
]

{ #category : #printing }
SoilUnitOfWork >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' ' << index printString 
	
]

{ #category : #'as yet unclassified' }
SoilUnitOfWork >> readFrom: aStream [ 
	| pageCode entry size |
	index := (aStream next: 8) asInteger.
	size := (aStream next: 3) asInteger.
	(1 to: size) do: [ :n | 
		pageCode := aStream next asInteger.
		entry := (SoilJournalEntry withTypeCode: pageCode) new.
		entries add: (entry readFrom: aStream) ]
]

{ #category : #accessing }
SoilUnitOfWork >> readVersion [
	^ entries first readVersion
]

{ #category : #accessing }
SoilUnitOfWork >> size [ 
	^ entries size
]

{ #category : #validating }
SoilUnitOfWork >> validateIn: aSoilTransaction [ 
	entries do: [ :each | each validateIn: aSoilTransaction ]
]

{ #category : #writing }
SoilUnitOfWork >> writeOn: aStream [
	aStream nextPutAll: (index asByteArrayOfSize: 8).
	"write the size of entries. The size is increased by one for the
	checkpoint entry that will be written at the end."
	aStream nextPutAll: (entries size asByteArrayOfSize: 3) + 1.
	entries do: [ :each | each writeOn: aStream ].
	aStream 
		flush
]

{ #category : #writing }
SoilUnitOfWork >> writeVersion [
	^ entries first transactionId
]
