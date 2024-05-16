Extension { #name : 'False' }

{ #category : '*Soil-Serializer' }
False >> soilBasicSerialize: serializer [
	serializer nextPutFalse: self
]

{ #category : '*Soil-Serializer' }
False >> soilSerialize: serializer [
	self soilBasicSerialize: serializer 
]
