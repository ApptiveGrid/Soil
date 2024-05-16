Extension { #name : 'CompiledBlock' }

{ #category : '*Soil-Serializer' }
CompiledBlock >> soilBasicSerialize: serializer [
	serializer nextPutCompiledBlock: self
]

{ #category : '*Soil-Serializer' }
CompiledBlock class >> soilMaterialize: materializer [ 
	^ materializer nextCompiledBlock: self
]
