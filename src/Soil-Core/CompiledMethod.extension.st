Extension { #name : #CompiledMethod }

{ #category : #'*Soil-Core' }
CompiledMethod >> soilBasicSerialize: serializer [
	serializer nextPutCompiledMethod: self
]

{ #category : #'*Soil-Core' }
CompiledMethod class >> soilMaterialize: materializer [ 
	^ materializer nextCompiledMethod: self
]
