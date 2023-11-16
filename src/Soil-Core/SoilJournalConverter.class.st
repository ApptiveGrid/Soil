Class {
	#name : #SoilJournalConverter,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SoilJournalConverter >> convert [ 
	| allJournalFiles |
	"reset database checkpoint to process all of the transaction logs and set the 
	right position at the end"
	soil settings checkpoint: (SoilLogSequenceNumber fileNumber: 0 offset: 0).
	"remove any existing current fragment file to be sure"
	soil journal resetFragmentFile.
	"read all transaction logs recursively, sort them and import to the new journal"
	allJournalFiles := ((soil path / #journal) allChildrenMatching: '*.journal') 
		sorted: [ :a :b | a withoutExtension basename asInteger < b withoutExtension basename asInteger ].
	allJournalFiles do: [ :each | | stream |
		stream := each binaryReadStream.
		soil journal importTransactionJournal: (SoilTransactionJournal readFrom: stream).
		stream close.
		each delete ].
	"write a final checkpoint record and about its position in the database"
	soil journal checkpoint


]

{ #category : #accessing }
SoilJournalConverter >> soil: aSoil [ 
	soil := aSoil
]
