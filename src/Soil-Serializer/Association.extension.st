Extension { #name : 'Association' }

{ #category : '*Soil-Serializer' }
Association >> soilBasicSerialize: serializer [
	self class == Association ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutAssociation: self
]

{ #category : '*Soil-Serializer' }
Association class >> soilMaterialize: materializer [ 
	^ materializer nextAssociation: self
]
