Extension { #name : #Array }

{ #category : #'*Soil-Core' }
Array >> soilSizeInMemory [
	"recursive #sizeInMemory for Soil. 
	Note: only works for some objects, e.g. SoilPersistentClusterVersion"
	^ self sizeInMemory + (self sum: #soilSizeInMemory)
]
