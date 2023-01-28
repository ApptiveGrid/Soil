Extension { #name : #AbstractLayout }

{ #category : #'*Soil-Serializer' }
AbstractLayout >> soilBasicMaterialize: objectClass with: materializer [
	self subclassResponsibility
]

{ #category : #'*Soil-Serializer' }
AbstractLayout >> soilBasicSerialize: anObject with: serializer [
	self subclassResponsibility
]

{ #category : #'*Soil-Serializer' }
AbstractLayout >> soilSerializeBehaviorDescription: anObject with: serializer [
	| description |
	description := serializer behaviorDescriptionFor: anObject class.
	serializer
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description objectId index);
		nextPutLengthEncodedInteger: (description version).
	^ description
]
