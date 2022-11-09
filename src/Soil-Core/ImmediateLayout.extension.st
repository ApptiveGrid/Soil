Extension { #name : #ImmediateLayout }

{ #category : #'*Soil-Core' }
ImmediateLayout >> soilBasicMaterialize: objectClass with: serializer [
	<ignoreForCoverage>
	"Immediate Objects are all serialized with their own TypeCode"
	self error: 'this should never be called'
]

{ #category : #'*Soil-Core' }
ImmediateLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	"Immediate Objects are all serialized with their own TypeCode"
	self error: 'this should never be called'
]
