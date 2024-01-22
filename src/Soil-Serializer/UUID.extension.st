Extension { #name : #UUID }

{ #category : #'*Soil-Serializer' }
UUID >> soilBasicSerialize: serializer [
	self class == UUID ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutUUID: self
]

{ #category : #'*Soil-Serializer' }
UUID class >> soilMaterialize: materializer [

	^ materializer nextUUID: self
]
