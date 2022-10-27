Extension { #name : #False }

{ #category : #'*Soil-Core' }
False >> soilBasicSerialize: serializer [
	serializer nextPutFalse: self
]

{ #category : #'*Soil-Core' }
False >> soilSerialize: serializer [
	self soilBasicSerialize: serializer 
]
