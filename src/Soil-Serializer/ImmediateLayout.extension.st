Extension { #name : 'ImmediateLayout' }

{ #category : '*Soil-Serializer' }
ImmediateLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	<ignoreForCoverage>
	"Immediate Objects are all serialized with their own TypeCode"
	self error: 'this should never be called'
]

{ #category : '*Soil-Serializer' }
ImmediateLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	"Immediate Objects are all serialized with their own TypeCode"
	self error: 'this should never be called'
]
