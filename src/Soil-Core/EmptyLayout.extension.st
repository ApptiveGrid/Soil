Extension { #name : #EmptyLayout }

{ #category : #'*Soil-Core' }
EmptyLayout >> soilBasicSerialize: anObject with: serializer [
	<ignoreForCoverage>
	self error: 'this should never be called'
]
