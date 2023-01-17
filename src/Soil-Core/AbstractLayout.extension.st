Extension { #name : #AbstractLayout }

{ #category : #'*Soil-Core' }
AbstractLayout >> soilBasicMaterialize: objectClass with: materializer [
	self subclassResponsibility
]

{ #category : #'*Soil-Core' }
AbstractLayout >> soilBasicSerialize: anObject with: serializer [
	self subclassResponsibility
]

{ #category : #'*Soil-Core' }
AbstractLayout >> soilSerializeBehaviorDescription: anObject with: serializer [
	| description |
	description := serializer behaviorDescriptionFor: anObject class.
	serializer
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description objectId index).
	^ description
]
