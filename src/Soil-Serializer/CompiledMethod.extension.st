Extension { #name : #CompiledMethod }

{ #category : #'*Soil-Serializer' }
CompiledMethod >> soilBasicSerialize: serializer [
	serializer nextPutCompiledMethod: self
]

{ #category : #'*Soil-Serializer' }
CompiledMethod class >> soilMaterialize: materializer [
	^ materializer nextCompiledMethod: self
]
