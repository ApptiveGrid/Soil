Class {
	#name : #SoilJournalSegmentFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilJournalSegmentFile class >> path: aFileReference [ 
	^ self new 
		path: aFileReference 
]

{ #category : #'initialize-release' }
SoilJournalSegmentFile >> close [
	stream close
]

{ #category : #'instance creation' }
SoilJournalSegmentFile >> create [
	path ensureCreateFile

]

{ #category : #'as yet unclassified' }
SoilJournalSegmentFile >> currentLogSequenceNumber [ 
	^ SoilLogSequenceNumber fileNumber: path pathSegments last asInteger offset: stream position 
]

{ #category : #testing }
SoilJournalSegmentFile >> hasSpace [
	^ stream position < "(2 raisedTo: 24)" 128
]

{ #category : #'instance creation' }
SoilJournalSegmentFile >> open [
	stream := path binaryReadWriteStream 
]

{ #category : #accessing }
SoilJournalSegmentFile >> path [
	^ path
]

{ #category : #accessing }
SoilJournalSegmentFile >> path: aFileReference [ 
	path := aFileReference 
]

{ #category : #utilities }
SoilJournalSegmentFile >> prefix [
	^ 'SOIL|SEGMENT FILE' asByteArray
]

{ #category : #printing }
SoilJournalSegmentFile >> printOn: aStream [ 
	aStream 
		<< 'journal segment file: '
		<< path asString
]

{ #category : #accessing }
SoilJournalSegmentFile >> soil [ 
	self halt
]

{ #category : #writing }
SoilJournalSegmentFile >> writeCheckpointEntry: aSoilNewCheckpointEntry [ 
	aSoilNewCheckpointEntry writeOn: stream.
	stream flush

]

{ #category : #writing }
SoilJournalSegmentFile >> writeTransactionLog: aSoilTransactionJournal [
	aSoilTransactionJournal writeOn: stream.
	stream flush
]
