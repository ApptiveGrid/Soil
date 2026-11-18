Extension { #name : #ZnBufferedWriteStream }

{ #category : #'*Soil-Common' }
ZnBufferedWriteStream >> soilNextBytesPutAll: aCollection [
	^ self nextPutAll: aCollection
]
