Extension { #name : #Integer }

{ #category : #'*Soil-Core' }
Integer >> asIndexKeyOfSize: keySize [ 
	^ (self asByteArrayOfSize: keySize) asInteger
]

{ #category : #'*Soil-Core' }
Integer >> asLogSequenceNumber [ 
	^ SoilLogSequenceNumber value: self
]

{ #category : #'*soil-core' }
Integer >> asSoilObjectId [
	^ (self asByteArrayOfSize: 8) asSoilObjectId 
]
