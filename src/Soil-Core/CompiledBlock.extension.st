Extension { #name : #CompiledBlock }

{ #category : #'*Soil-Core' }
CompiledBlock >> soilBasicSerialize: serializer [
	serializer nextPutCompiledBlock: self
]

{ #category : #'*Soil-Core' }
CompiledBlock class >> soilMaterialize: materializer [ 
	^ materializer nextCompiledBlock: self
]
