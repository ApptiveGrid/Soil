Class {
	#name : #SOJournalEntry,
	#superclass : #Object,
	#category : #'Soil-Core'
}

{ #category : #writing }
SOJournalEntry >> writeOn: aStream [ 
	aStream nextPut: self class journalTypeCode
	
]
