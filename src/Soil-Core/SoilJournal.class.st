Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'soil',
		'indexOffset',
		'semaphore',
		'currentSegmentFile',
		'unitsOfWork'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visting }
SoilJournal >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitJournal: self
]

{ #category : #adding }
SoilJournal >> addUnitOfWork: aSoilUnitOfWork [ 
	semaphore critical: [  
		self verifyNextJournalIndex: aSoilUnitOfWork index.	
		unitsOfWork at: aSoilUnitOfWork index put: aSoilUnitOfWork  ]

]

{ #category : #queries }
SoilJournal >> allHavingEntriesMatching: aBlock [
	| result |
	result := OrderedCollection new.
	self allUnitsOfWorkDo: [ :journal |
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
SoilJournal >> allUnitsOfWork [
	| all |
	all := OrderedCollection new.
	self allUnitsOfWorkDo: [ :transactionJournal | all add: transactionJournal ].
	^ all
]

{ #category : #enumerating }
SoilJournal >> allUnitsOfWorkDo: aBlock [
	self halt.
]

{ #category : #writing }
SoilJournal >> append: aSoilTransactionJournal [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilTransactionJournal index.	
		self fragmentFileForWriting writeUnitOfWork: aSoilTransactionJournal ]

]

{ #category : #copying }
SoilJournal >> copyFrom: start to: end [ 
	^ self class new 
		soil: soil;
		unitsOfWork: (self unitsOfWork select: [:each | each index between: start and: end])
]

{ #category : #'as yet unclassified' }
SoilJournal >> createFragmentFile: filename [
	(self path / filename) ensureCreateFile.
	^ (self openFragmentFile: filename)
		initializeFilesystem;
		yourself
]

{ #category : #'as yet unclassified' }
SoilJournal >> currentFragmentFile [
	| currentLSN |
	^ currentSegmentFile ifNil: [  
		currentLSN := soil settings checkpoint.
		currentSegmentFile := (currentLSN isInitial) 
			ifTrue: [ self createFragmentFile: currentLSN filename ]
			ifFalse: [ self openFragmentFile: currentLSN filename ] ]
]

{ #category : #enumerating }
SoilJournal >> do: aBlock [ 
	semaphore critical: [  
		unitsOfWork do: aBlock ]	
]

{ #category : #'as yet unclassified' }
SoilJournal >> fragmentFileForWriting [
	| segmentFile nextFilename |
	segmentFile := self currentFragmentFile.
	^ currentSegmentFile hasSpace 
		ifTrue: [ currentSegmentFile ]
		ifFalse: [ 
			nextFilename := currentSegmentFile currentLogSequenceNumber nextFilename.
			currentSegmentFile close.
			currentSegmentFile := self createFragmentFile: nextFilename ]
]

{ #category : #'as yet unclassified' }
SoilJournal >> importEntry: aSoilTransactionJournal [ 
	| id local |
	id := aSoilTransactionJournal index.
	local := (self newUnitOfWorkFor: id)
		addEntries: aSoilTransactionJournal entries;
		write;
		close.
	self addUnitOfWork: local
]

{ #category : #initialization }
SoilJournal >> initialize [ 
	super initialize.
	unitsOfWork := LRUCache new maximumWeight: 20.
	semaphore := Mutex new.
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
		items: (self unitsOfWork);
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
SoilJournal >> lastUnitOfWork [
	^ unitsOfWork 
		ifNotEmpty: [ :journals | journals at: journals keys max ]
		ifEmpty: nil
]

{ #category : #'instance creation' }
SoilJournal >> newUnitOfWorkFor: anInteger [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: anInteger.
		SoilUnitOfWork new 
			index: anInteger ]
]

{ #category : #'instance creation' }
SoilJournal >> open [ 
	
]

{ #category : #'as yet unclassified' }
SoilJournal >> openFragmentFile: filename [ 
	^ (SoilJournalFragmentFile path: self path / filename )
		open;
		yourself
]

{ #category : #accessing }
SoilJournal >> path [
	^ soil path / #journal
]

{ #category : #accessing }
SoilJournal >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #accessing }
SoilJournal >> unitsOfWork [
self halt.
	^ unitsOfWork
]

{ #category : #accessing }
SoilJournal >> unitsOfWork: aCollection [ 
	unitsOfWork := aCollection
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
SoilJournal >> writeUnitOfWork: aSoilUnitOfWork [ 
	^ semaphore critical: [  
		self verifyNextJournalIndex: aSoilUnitOfWork index.	
		self fragmentFileForWriting writeUnitOfWork: aSoilUnitOfWork ]

]
