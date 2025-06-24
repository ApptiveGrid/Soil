Class {
	#name : #SoilTransactionJournal,
	#superclass : #Object,
	#instVars : [
		'index',
		'entries'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilTransactionJournal class >> readFrom: aStream [ 
	^ self new 
		readFrom: aStream;
		yourself
]

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
	aJournalEntry journal: self.
	entries add: aJournalEntry 
]

{ #category : #searching }
SoilTransactionJournal >> anyEntrySatisfy: aBlock [
	^ entries anySatisfy: aBlock
]

{ #category : #committing }
SoilTransactionJournal >> commitIn: soil [ 
	self commitIn: soil recovery: false 
]

{ #category : #committing }
SoilTransactionJournal >> commitIn: soil recovery: aBoolean [
	entries do: [ :each | each commitIn: soil recovery: aBoolean ]
]

{ #category : #committing }
SoilTransactionJournal >> committedAt [
	^ entries last committedAt 
]

{ #category : #accessing }
SoilTransactionJournal >> createdAt [
	^ entries first createdAt
]

{ #category : #accessing }
SoilTransactionJournal >> duration [
	^ (self committedAt - self createdAt) asMilliSeconds  
]

{ #category : #accessing }
SoilTransactionJournal >> entries [
	^ entries
]

{ #category : #accessing }
SoilTransactionJournal >> entries: aCollection [ 
	entries := aCollection
]

{ #category : #searching }
SoilTransactionJournal >> entriesMatching: aBlock [
	^ entries select: aBlock
]

{ #category : #accessing }
SoilTransactionJournal >> entryAt: anInteger [ 
	^ entries at: anInteger 
]

{ #category : #accessing }
SoilTransactionJournal >> index [

	^ index
]

{ #category : #accessing }
SoilTransactionJournal >> index: anObject [

	index := anObject
]

{ #category : #initialization }
SoilTransactionJournal >> initialize [ 
	super initialize.
	entries := OrderedCollection new
]

{ #category : #inspector }
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

{ #category : #accessing }
SoilTransactionJournal >> path: aFileReference [ 
	self shouldBeImplemented.
]

{ #category : #printing }
SoilTransactionJournal >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' ' << index printString 
	
]

{ #category : #'reading-writing' }
SoilTransactionJournal >> readFrom: aStream [ 
	| entry |
	[ aStream atEnd ] whileFalse: [
		entry := SoilJournalEntry readFrom: aStream.
		index 
			ifNotNil: [ 
				(index = entry transactionId) 
					ifFalse: [ Error signal: 'transaction changed without checkpoint record' ] ]
			ifNil: [ index := entry transactionId ].
		entries add: entry.
		entry isCommitEntry ifTrue: [ ^ self ] ]
]

{ #category : #accessing }
SoilTransactionJournal >> readVersion [
	^ entries first readVersion
]

{ #category : #accessing }
SoilTransactionJournal >> size [ 
	^ entries size
]

{ #category : #validating }
SoilTransactionJournal >> validateIn: aSoilTransaction [ 
	entries do: [ :each | each validateIn: aSoilTransaction ]
]

{ #category : #'reading-writing' }
SoilTransactionJournal >> writeOn: aStream [
	entries do: [ :each | each writeOn: aStream ].
	aStream 
		flush
]

{ #category : #'reading-writing' }
SoilTransactionJournal >> writeVersion [
	^ entries first transactionId
]
