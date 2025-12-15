Extension { #name : #Array }

{ #category : #'*Soil-Core' }
Array >> soilSizeInMemory [
	^ self sizeInMemory + (self sum: #soilSizeInMemory)
]
