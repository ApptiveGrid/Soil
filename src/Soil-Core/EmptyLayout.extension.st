Extension { #name : #EmptyLayout }

{ #category : #'*Soil-Core' }
EmptyLayout >> soilBasicMaterialize: objectClass with: serializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]

{ #category : #'*Soil-Core' }
EmptyLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]
