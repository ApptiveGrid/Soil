Class {
	#name : #SoilJournalSegmentFile,
	#superclass : #Object,
	#instVars : [
		'path',
		'stream'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilJournalSegmentFile class >> path: aFileReference [ 
	^ self new 
		path: aFileReference 
]

{ #category : #'instance creation' }
SoilJournalSegmentFile >> create [
	path ensureCreateFile

]

{ #category : #'as yet unclassified' }
SoilJournalSegmentFile >> currentLogSequenceNumber [ 
	^ SoilLogSequenceNumber fileNumber: path pathSegments last asInteger offset: stream position 
]

{ #category : #'instance creation' }
SoilJournalSegmentFile >> open [
	stream := path binaryReadWriteStream 
]

{ #category : #accessing }
SoilJournalSegmentFile >> path: aFileReference [ 
	path := aFileReference 
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
