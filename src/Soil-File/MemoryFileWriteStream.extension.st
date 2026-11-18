Extension { #name : #MemoryFileWriteStream }

{ #category : #'*Soil-File' }
MemoryFileWriteStream >> soilNextBytesPutAll: aCollection [
	^ self stream nextPutAll: aCollection
]
