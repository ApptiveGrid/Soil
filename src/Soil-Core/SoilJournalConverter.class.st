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
	(soil path / #'journal.bak') ensureCreateDirectory.
	allJournalFiles := ((soil path / #journal) allChildrenMatching: '*.journal') 
		sorted: [ :a :b | a withoutExtension basename asInteger < b withoutExtension basename asInteger ].
	allJournalFiles do: [ :each | | stream |
		stream := each binaryReadStream.
		soil replayTransactionJournal: (SoilTransactionJournal readFrom: stream).
		stream close.
		soil journal checkpoint.
		[each moveTo: soil path / #'journal.bak']
			on: FileExists do: [ :e | ] ].


]

{ #category : #accessing }
SoilJournalConverter >> soil: aSoil [ 
	soil := aSoil
]
