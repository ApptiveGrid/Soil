Extension { #name : #Integer }

{ #category : #'*Soil-Core' }
Integer >> asLogSequenceNumber [ 
	^ SoilLogSequenceNumber value: self
]

{ #category : #'*Soil-Core' }
Integer >> asSkipListKeyOfSize: keySize [ 
	^ self asByteArrayOfSize: keySize 
]

{ #category : #'*soil-core' }
Integer >> asSoilObjectId [
	^ (self asByteArrayOfSize: 8) asSoilObjectId 
]
