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

{ #category : #visiting }
SoilJournalFragmentFile >> acceptSoil: aSoilVisitor [ 
	aSoilVisitor visitJournalFragmentFile: self
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
	self stream position: self headerSize.
	^ DateAndTime fromUnixTime: (stream next: self createdSize) asInteger
]

{ #category : #initialization }
SoilJournalFragmentFile >> created: aDateandTime [
	| timestamp |
	timestamp := aDateandTime asUnixTime.
	stream 
		position: self headerSize;
		nextPutAll: (timestamp asByteArrayOfSize: self createdSize);
		flush
]

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> createdSize [
	^ 6
]

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> currentLogSequenceNumber [ 
	^ SoilLogSequenceNumber fileNumber: (ByteArray readHexFrom: path pathSegments last) asInteger offset: stream position 
]

{ #category : #accessing }
SoilJournalFragmentFile >> filename [ 
	^ self path basename
]

{ #category : #accessing }
SoilJournalFragmentFile >> firstTransactionId [
	^ self firstTransactionJournal index
]

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> firstTransactionJournal [
	self stream position: self headerSize + 6.
	^ SoilTransactionJournal readFrom: stream underlyingStream
]

{ #category : #testing }
SoilJournalFragmentFile >> hasSpace [
	"a fragment file when writing to it must be smaller be with a 
	file size of 24 bit = 16MB"
	^ stream position < (2 raisedTo: 24)
]

{ #category : #initialization }
SoilJournalFragmentFile >> initializeStart [ 
	self created: DateAndTime now
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
			title: #checkpoint;
			evaluated: #checkpointedAt)
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

{ #category : #accessing }
SoilJournalFragmentFile >> soil [ 
	self halt
]

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> transactionJournals [
	| transactionJournals |
	self stream position: self headerSize + 6.
	transactionJournals := OrderedCollection new.
	[ stream atEnd ] whileFalse: [  
		transactionJournals add: (SoilTransactionJournal readFrom: stream underlyingStream) ].
	^ transactionJournals
]

{ #category : #writing }
SoilJournalFragmentFile >> writeCheckpointEntry: aSoilNewCheckpointEntry [ 
	stream setToEnd.
	aSoilNewCheckpointEntry writeOn: stream.
	stream flush

]

{ #category : #writing }
SoilJournalFragmentFile >> writeIncompleteTransactionJournal: aTransactionJournal [
	stream setToEnd.
	aTransactionJournal writeIncompleteOn: stream.
	stream flush
]

{ #category : #writing }
SoilJournalFragmentFile >> writeTransactionJournal: aTransactionJournal [
	stream setToEnd.
	aTransactionJournal writeOn: stream.
	stream flush
]
