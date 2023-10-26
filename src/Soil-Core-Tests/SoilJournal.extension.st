Extension { #name : #SoilJournal }

{ #category : #'*Soil-Core-Tests' }
SoilJournal >> lastIndex [
	^ self lastUnitOfWork 
		ifNotNil: [ :journal | journal index ]
		ifNil: [ 0 ]
]
