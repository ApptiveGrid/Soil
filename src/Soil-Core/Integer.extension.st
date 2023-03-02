Extension { #name : #Integer }

{ #category : #'*Soil-Core' }
Integer >> asSkipListKeyOfSize: keySize [ 
	^ self asByteArrayOfSize: keySize 
]
