Extension { #name : #True }

{ #category : #'*Soil-Core' }
True >> soilBasicSerialize: serializer [
	serializer nextPutTrue: self
]

{ #category : #'*Soil-Core' }
True >> soilSerialize: serializer [
	self soilBasicSerialize: serializer
]
