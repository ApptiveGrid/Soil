Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilJournal >> allTransactionJournals [
	| files |
	files := path childrenMatching: '*.journal'.
	^ files sorted collect: [ :each | 
		(SoilTransactionJournal new on: each)
			readAll ]
]

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ SoilTransactionJournal new 
		on: path / anInteger asString , #journal
]

{ #category : #enumerating }
SoilJournal >> do: aBlock [ 
	self allTransactionJournals do: aBlock
	
]

{ #category : #'as yet unclassified' }
SoilJournal >> inspectionContent [
	<inspectorPresentationOrder: 0 title: 'journal entries'>

	^ SpComponentListPresenter new
		items: (self allTransactionJournals collect: #inspectionEntries)
]

{ #category : #accessing }
SoilJournal >> path: aFileReference [ 
	path := aFileReference 
]
