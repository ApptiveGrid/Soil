Extension { #name : 'True' }

{ #category : '*Soil-Serializer' }
True >> soilBasicSerialize: serializer [
	serializer nextPutTrue: self
]

{ #category : '*Soil-Serializer' }
True >> soilSerialize: serializer [
	self soilBasicSerialize: serializer 
]
