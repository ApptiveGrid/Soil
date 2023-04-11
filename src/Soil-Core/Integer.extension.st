Extension { #name : #Integer }

{ #category : #'*Soil-Core' }
Integer >> asSkipListKeyOfSize: keySize [ 
	^ self asByteArrayOfSize: keySize 
]

{ #category : #'*soil-core' }
Integer >> asSoilObjectId [
	^ self asByteArray asSoilObjectId 
]
