Class {
	#name : #SoilJournalFragmentFile,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Model'
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

{ #category : #'as yet unclassified' }
SoilJournalFragmentFile >> currentLogSequenceNumber [ 
	^ SoilLogSequenceNumber fileNumber: path pathSegments last asInteger offset: stream position 
]

{ #category : #testing }
SoilJournalFragmentFile >> hasSpace [
	^ stream position < "(2 raisedTo: 24)" 128
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
	^ 'SOIL|SEGMENT FILE' asByteArray
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

{ #category : #writing }
SoilJournalFragmentFile >> writeCheckpointEntry: aSoilNewCheckpointEntry [ 
	aSoilNewCheckpointEntry writeOn: stream.
	stream flush

]

{ #category : #writing }
SoilJournalFragmentFile >> writeTransactionJournal: aSoilTransactionJournal [
	aSoilTransactionJournal writeOn: stream.
	stream flush
]
