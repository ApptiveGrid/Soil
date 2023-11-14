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
	allJournalFiles := ((soil path / #journal) allChildrenMatching: '*.journal') 
		sorted: [ :a :b | a withoutExtension basename asInteger < b withoutExtension basename asInteger ].
	allJournalFiles do: [ :each | | stream |
		stream := each binaryReadStream.
		soil journal importTransactionJournal: (SoilTransactionJournal readFrom: stream).
		stream close.
		soil journal checkpoint.
		each delete ].


]

{ #category : #accessing }
SoilJournalConverter >> soil: aSoil [ 
	soil := aSoil
]
