Extension { #name : #WideString }

{ #category : #'*Soil-Core' }
WideString >> soilBasicSerialize: serializer [
	
	serializer nextPutWideString: self
]
