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
SoilJournalFragmentFile >> inspectionUnitsOfWork [
	<inspectorPresentationOrder: 0 title: 'units of work'>

	^ SpTablePresenter new
		items: (self unitsOfWork reversed);
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
SoilJournalFragmentFile >> unitsOfWork [
	| unitsOfWork |
	stream position: self headerSize + 6.
	unitsOfWork := OrderedCollection new.
	[ stream atEnd ] whileFalse: [  
		unitsOfWork add: (SoilUnitOfWork readFrom: stream underlyingStream) ].
	^ unitsOfWork
]

{ #category : #writing }
SoilJournalFragmentFile >> writeCheckpointEntry: aSoilNewCheckpointEntry [ 
	stream setToEnd.
	aSoilNewCheckpointEntry writeOn: stream.
	stream flush

]

{ #category : #writing }
SoilJournalFragmentFile >> writeUnitOfWork: aSoilUnitOfWork [
	stream setToEnd.
	aSoilUnitOfWork writeOn: stream.
	stream flush
]
