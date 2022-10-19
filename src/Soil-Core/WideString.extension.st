Extension { #name : #WideString }

{ #category : #'*Soil-Core' }
WideString >> soilBasicSerialize: serializer [
	
	serializer nextPutWideString: self
]

{ #category : #'*Soil-Core' }
WideString class >> soilMaterialize: materializer [

	^ materializer nextWideString
]
