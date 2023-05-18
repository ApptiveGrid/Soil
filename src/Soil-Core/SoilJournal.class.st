Class {
	#name : #SoilJournal,
	#superclass : #Object,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilJournal >> at: anInteger [ 
	^ SoilTransactionJournal new 
		on: path / anInteger asString , #journal
]

{ #category : #accessing }
SoilJournal >> path: aFileReference [ 
	path := aFileReference 
]
