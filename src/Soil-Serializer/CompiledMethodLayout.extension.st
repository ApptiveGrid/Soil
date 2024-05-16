Extension { #name : 'CompiledMethodLayout' }

{ #category : '*Soil-Serializer' }
CompiledMethodLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	<ignoreForCoverage>
	"CompiledMethod Objects are all serialized with their own TypeCode"
	self error: 'this should never be called'
]

{ #category : '*Soil-Serializer' }
CompiledMethodLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	"CompiledMethod Objects are all serialized with their own TypeCode
	SoilSerializer>>#nextPutCompiledMethod:
	SoilSerializer>>#nextPutCompiledBlock:"
	self error: 'this should never be called'
]
