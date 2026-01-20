Extension { #name : #OrderedCollection }

{ #category : #'*Soil-Core' }
OrderedCollection >> soilSizeInMemory [
	"recursive #sizeInMemory for Soil. 
	Note: only works for some objects, e.g. SoilPersistentClusterVersion"
	^ self sizeInMemory 
		+ array soilSizeInMemory
]
