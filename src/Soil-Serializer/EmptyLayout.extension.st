Extension { #name : 'EmptyLayout' }

{ #category : '*Soil-Serializer' }
EmptyLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]

{ #category : '*Soil-Serializer' }
EmptyLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]
