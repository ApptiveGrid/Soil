Extension { #name : #SoilJournal }

{ #category : #'*Soil-Core-Tests' }
SoilJournal >> lastIndex [
	^ self lastTransactionJournal 
		ifNotNil: [ :journal | journal index ]
		ifNil: [ 0 ]
]
