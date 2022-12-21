Extension { #name : #EmptyLayout }

{ #category : #'*Soil-Core' }
EmptyLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]

{ #category : #'*Soil-Core' }
EmptyLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]
