Extension { #name : #Object }

{ #category : #'*Soil-Common' }
Object >> soilSizeInMemory [
	"recursive #sizeInMemory for Soil. 
	Note: only works for some objects, e.g. SoilPersistentClusterVersion"
	^ self sizeInMemory 
]
