Extension { #name : #Soil }

{ #category : #'*Soil-Core-Tests' }
Soil class >> inMemory [ 
	^ self new 
		path: FileSystem memory root
]
