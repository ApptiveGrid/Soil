Extension { #name : #WideString }

{ #category : #'*Soil-Serializer' }
WideString >> soilBasicSerialize: serializer [

	serializer nextPutWideString: self
]

{ #category : #'*Soil-Serializer' }
WideString class >> soilMaterialize: materializer [

	^ materializer nextWideString
]
