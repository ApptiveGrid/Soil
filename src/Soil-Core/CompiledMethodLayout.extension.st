Extension { #name : #CompiledMethodLayout }

{ #category : #'*Soil-Core' }
CompiledMethodLayout >> soilBasicMaterialize: objectClass with: serializer [
	<ignoreForCoverage>
	"CompiledMethod Objects are all serialized with their own TypeCode"
	self error: 'this should never be called'
]

{ #category : #'*Soil-Core' }
CompiledMethodLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	"CompiledMethod Objects are all serialized with their own TypeCode
	SoilSerializer>>#nextPutCompiledMethod:
	SoilSerializer>>#nextPutCompiledBlock:"
	self error: 'this should never be called'
]
