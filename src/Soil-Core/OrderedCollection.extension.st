Extension { #name : #OrderedCollection }

{ #category : #'*Soil-Core' }
OrderedCollection >> soilSizeInMemory [
	^ self sizeInMemory 
		+ array soilSizeInMemory
]
