Class {
	#name : #SoilJournalEntry,
	#superclass : #Object,
	#category : #'Soil-Core-Journal'
}

{ #category : #writing }
SoilJournalEntry >> writeOn: aStream [ 
	aStream nextPut: self class journalTypeCode
	
]
