Extension { #name : #EmptyLayout }

{ #category : #'*Soil-Core' }
EmptyLayout >> soilBasicSerialize: anObject with: serializer [
	self error: 'this should never be called'
]
