Class {
	#name : #SoilJournalFragmentFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Journal'
}

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
	| position |
	stream setToEnd.
	position := stream position.
	aSoilJournalEntry writeOn: stream.
	stream flush.
	^ position

]

{ #category : #'initialize-release' }
SoilJournalFragmentFile >> close [
	stream close
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

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> createdSize [
	^ 6
]

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> currentLogSequenceNumber [ 
	^ SoilLogSequenceNumber 
		fileNumber: (ByteArray readHexFrom: path pathSegments last) asInteger 
		offset: stream position 
]

{ #category : #accessing }
SoilJournalFragmentFile >> dataPosition [
	^ self createdPosition + self createdSize 
]

{ #category : #accessing }
SoilJournalFragmentFile >> filename [ 
	^ self path basename
]

{ #category : #accessing }
SoilJournalFragmentFile >> firstTransactionId [
	self stream position: self headerSize + 6.

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

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> inspectionTransactionJournals [
	<inspectorPresentationOrder: 0 title: 'transaction journals'>

	^ SpTablePresenter new
		items: (self transactionJournals);
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
	stream := path binaryReadWriteStream 
]

{ #category : #accessing }
SoilJournalFragmentFile >> path [
	^ path
]

{ #category : #accessing }
SoilJournalFragmentFile >> path: aFileReference [ 
	aFileReference  isDirectory ifTrue: [ self halt ].
	path := aFileReference 
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

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> transactionJournals [
	| transactionJournals entry |
	self stream position: self dataPosition.
	transactionJournals := OrderedDictionary new.
	[ stream atEnd ] whileFalse: [  
		entry := SoilJournalEntry readFrom: stream underlyingStream.
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
