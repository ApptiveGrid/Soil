Extension { #name : #AbstractLayout }

{ #category : #'*Soil-Serializer' }
AbstractLayout >> soilBasicMaterialize: objectClass with: materializer [
	self subclassResponsibility
]

{ #category : #'*Soil-Serializer' }
AbstractLayout >> soilBasicSerialize: anObject with: serializer [
	self subclassResponsibility
]
