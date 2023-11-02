Class {
	#name : #SoilMemoryDatabaseJournal,
	#superclass : #SoilDatabaseJournal,
	#category : #'Soil-Core-Journal'
}

{ #category : #initialization }
SoilMemoryDatabaseJournal >> initialize [ 
	super initialize.
	transactionJournals := Dictionary new
]

{ #category : #accessing }
SoilMemoryDatabaseJournal >> transactionJournalsStartingAt: index do: aBlock [ 
	^ (transactionJournals select: [ :each | each index >= index ])	
		do: aBlock

]
