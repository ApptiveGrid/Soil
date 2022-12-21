Extension { #name : #AbstractLayout }

{ #category : #'*Soil-Core' }
AbstractLayout >> soilBasicMaterialize: objectClass with: materializer [
	self subclassResponsibility
]

{ #category : #'*Soil-Core' }
AbstractLayout >> soilBasicSerialize: anObject with: serializer [
	self subclassResponsibility
]
