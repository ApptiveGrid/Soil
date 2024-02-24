Class {
	#name : #SoilJournalFragmentFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile class >> filenameFromFilenumber: anInteger [ 
	^ (anInteger printStringBase: 16 length: 10 padded: true) asLowercase 
]

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile class >> filenumberFromFilename: aString [ 
	^ (ByteArray readHexFrom: aString) asInteger
]

{ #category : #accessing }
SoilJournalFragmentFile class >> path: aFileReference [ 
	^ self new 
		path: aFileReference 
]

{ #category : #versions }
SoilJournalFragmentFile class >> version [
	^ 1
]

{ #category : #visiting }
SoilJournalFragmentFile >> acceptSoil: aSoilVisitor [ 
	aSoilVisitor visitJournalFragmentFile: self
]

{ #category : #writing }
SoilJournalFragmentFile >> appendEntry: aSoilJournalEntry [ 
	| position lock |
	"lock whole file for appending. The lock context here is
	the journal entry itself because there is no better 
	object to use. The lock should be really exclusive"
	lock := stream lockAppendingFor: aSoilJournalEntry.
	[ 
	 	"when the lock is in place it is safe the set the file 
		to its end"
		stream setToEnd.
		position := stream position.
		aSoilJournalEntry writeOn: stream.
		stream flush.
		stream fileStream dataSync ]
			ensure: [ lock release ].
	^ position

]

{ #category : #accessing }
SoilJournalFragmentFile >> atEnd [
	^ stream atEnd
]

{ #category : #accessing }
SoilJournalFragmentFile >> basename [ 
	^ path basename
]

{ #category : #'open/close' }
SoilJournalFragmentFile >> close [
	stream close
]

{ #category : #copying }
SoilJournalFragmentFile >> copyTo: aPath [ 
	path copyTo: aPath
]

{ #category : #'instance creation' }
SoilJournalFragmentFile >> create [
	path ensureCreateFile
]

{ #category : #accessing }
SoilJournalFragmentFile >> created [
	self stream position: self createdPosition.
	^ DateAndTime fromUnixTime: (stream next: self createdSize) asInteger
]

{ #category : #accessing }
SoilJournalFragmentFile >> createdPosition [
	^ self versionPosition + self versionSize 
]

{ #category : #accessing }
SoilJournalFragmentFile >> createdSize [
	^ 6
]

{ #category : #accessing }
SoilJournalFragmentFile >> currentLogSequenceNumber [ 
	^ SoilLogSequenceNumber 
		fileNumber: (self class filenumberFromFilename: path basename) 
		offset: stream position 
]

{ #category : #accessing }
SoilJournalFragmentFile >> dataPosition [
	^ self createdPosition + self createdSize 
]

{ #category : #searching }
SoilJournalFragmentFile >> entriesMatching: aBlock [
	^ self transactionJournals flatCollect: [ :journal |
		journal entriesMatching: aBlock ]
]

{ #category : #accessing }
SoilJournalFragmentFile >> fileNumber [
	^ self class filenumberFromFilename: path basename
]

{ #category : #accessing }
SoilJournalFragmentFile >> filename [ 
	^ self path basename
]

{ #category : #accessing }
SoilJournalFragmentFile >> firstTransactionId [
	self stream position: self dataPosition.
	self flag: #todo.
	"we skip the "
	((SoilJournalEntry readFrom: self stream) class = SoilCheckpointEntry) ifFalse: [ 
		Error signal: 'fragment file should start with a checkpoint entry' ].
	^ SoilTransactionJournalEntry readTransactionIdFrom: stream
]

{ #category : #testing }
SoilJournalFragmentFile >> hasSpace [
	"a fragment file when writing to it must be smaller be with a 
	file size of 24 bit = 16MB"
	^ stream position < (2 raisedTo: 24)
]

{ #category : #initialization }
SoilJournalFragmentFile >> initializeCreated [
	| timestamp |
	timestamp := DateAndTime now asUnixTime.
	stream 
		position: self createdPosition;
		nextPutAll: (timestamp asByteArrayOfSize: self createdSize);
		flush
]

{ #category : #initialization }
SoilJournalFragmentFile >> initializeStart [ 
	self initializeVersion.
	self initializeCreated 
]

{ #category : #initialization }
SoilJournalFragmentFile >> initializeVersion [ 
	self stream position: self headerSize.
	stream next: self class version.

]

{ #category : #inspector }
SoilJournalFragmentFile >> inspectionTransactionJournals [
	<inspectorPresentationOrder: 0 title: 'transaction journals'>

	^ SpTablePresenter new
		items: (self transactionJournals reverse);
		addColumn: (SpCompositeTableColumn new
			title: '#';
			width: 30;
			addColumn: (SpStringTableColumn evaluated: [:each | each index ]));
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
			title: #commit;
			evaluated: #committedAt)
]

{ #category : #'instance creation' }
SoilJournalFragmentFile >> open [
	stream := SoilLockableStream path: path 
]

{ #category : #accessing }
SoilJournalFragmentFile >> path [
	^ path
]

{ #category : #accessing }
SoilJournalFragmentFile >> path: aFileReference [
	path := aFileReference 
]

{ #category : #accessing }
SoilJournalFragmentFile >> position: anInteger [ 
	stream position: anInteger 
]

{ #category : #utilities }
SoilJournalFragmentFile >> prefix [
	^ 'SOIL|JOURNAL FRAGMENT' asByteArray
]

{ #category : #printing }
SoilJournalFragmentFile >> printOn: aStream [ 
	aStream 
		<< 'journal segment file: '
		<< path asString
]

{ #category : #initialization }
SoilJournalFragmentFile >> setToEnd [
	stream setToEnd
]

{ #category : #accessing }
SoilJournalFragmentFile >> setToStart [
	self stream position: self dataPosition
]

{ #category : #accessing }
SoilJournalFragmentFile >> size [ 
	^ stream size 
]

{ #category : #journal }
SoilJournalFragmentFile >> transactionJournals [
	| transactionJournals entry |
	self stream position: self dataPosition.
	transactionJournals := OrderedDictionary new.
	[ stream atEnd ] whileFalse: [  
		entry := SoilJournalEntry readFrom: stream.
		entry isTransactionEntry ifTrue: [ 
			(transactionJournals 
				at: entry transactionId
				ifAbsentPut: [ SoilTransactionJournal new index: entry transactionId ])
					addEntry: entry ] ].
	^ transactionJournals values
]

{ #category : #accessing }
SoilJournalFragmentFile >> version [
	self stream position: self versionPosition.
	^ stream next asInteger
]

{ #category : #versions }
SoilJournalFragmentFile >> versionPosition [
	^ self headerSize 
]

{ #category : #versions }
SoilJournalFragmentFile >> versionSize [
	^ 1
]
