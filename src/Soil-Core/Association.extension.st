Extension { #name : #Association }

{ #category : #'*Soil-Core' }
Association >> soilBasicSerialize: serializer [
	self class == Association ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutAssociation: self
]

{ #category : #'*Soil-Core' }
Association class >> soilMaterialize: materializer [ 
	^ materializer nextAssociation: self
]
