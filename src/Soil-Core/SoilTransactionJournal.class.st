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
	self addEntryToTail: aJournalEntry 
]

{ #category : #adding }
SoilTransactionJournal >> addEntryToHead: aJournalEntry [
	aJournalEntry journal: self.
	entries add: aJournalEntry after: entries first
]

{ #category : #adding }
SoilTransactionJournal >> addEntryToTail: aJournalEntry [
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
	"entries that write the bytes of an object and follow each other are written together,
	per segment in one go, and in the order they have here relative to the entries around
	them. Written one by one, each moved the file position and flushed twice, and where
	that is not cheap a commit of many records spent its time on it"
	| objectEntries |
	objectEntries := OrderedCollection new.
	entries do: [ :each |
		each writesObjectBytes
			ifTrue: [ objectEntries add: each ]
			ifFalse: [
				self commitObjectEntries: objectEntries in: soil.
				objectEntries := OrderedCollection new.
				each commitIn: soil recovery: aBoolean ] ].
	self commitObjectEntries: objectEntries in: soil
]

{ #category : #committing }
SoilTransactionJournal >> commitObjectEntries: aCollection in: soil [
	aCollection ifEmpty: [ ^ self ].
	(soil objectRepository putAll: (aCollection collect: [ :each | each objectId -> each bytes ]))
		with: aCollection
		do: [ :position :each | each wasWrittenAt: position ]
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

{ #category : #committing }
SoilTransactionJournal >> dropKeysAddedAndRemovedAgain [
	"a key this transaction added and removed again never has to reach the index, so both
	entries go. If the add overwrote a value the key had before, the removal stays and
	removes that value. The entries are in the order they were made: a removal pairs with
	the last add before it of its key and of the value it removes, and again with the add
	before that one if the value it removes now was added in this transaction as well"
	| adds dropped |
	adds := Dictionary new.
	dropped := IdentitySet new.
	entries do: [ :each |
		(each isKindOf: SoilAddKeyEntry) ifTrue: [
			(adds at: each id -> each key ifAbsentPut: [ OrderedCollection new ]) add: each ].
		(each isKindOf: SoilRemoveKeyEntry) ifTrue: [ | candidates add pairing |
			candidates := adds at: each id -> each key ifAbsent: [ OrderedCollection new ].
			pairing := true.
			[ pairing and: [
				(add := candidates reversed
					detect: [ :candidate | SoilIndexItemsPage value: candidate value matches: each oldValue ]
					ifNone: [ nil ]) notNil ] ] whileTrue: [
				candidates remove: add.
				dropped add: add.
				(add oldValue isNil or: [ add oldValue isRemoved ])
					ifTrue: [
						dropped add: each.
						pairing := false ]
					ifFalse: [ each oldValue: add oldValue ] ] ] ].
	entries := entries reject: [ :each | dropped includes: each ]
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

	index := anObject.
	entries ifNotEmpty: [ entries first transactionId: anObject ]
]

{ #category : #initialization }
SoilTransactionJournal >> initialize [ 
	super initialize.
	entries := OrderedCollection new
]

{ #category : #inspector }
SoilTransactionJournal >> inspectionEntries: aBuilder [ 
	<inspectorPresentationOrder: 0 title: 'journal entries'>

	^ aBuilder newTable 
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
