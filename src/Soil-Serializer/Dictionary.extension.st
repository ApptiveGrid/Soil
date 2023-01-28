Extension { #name : #Dictionary }

{ #category : #'*Soil-Serializer' }
Dictionary >> soilBasicSerialize: serializer [
	self class == Dictionary ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutDictionary: self
]

{ #category : #'*Soil-Serializer' }
Dictionary class >> soilMaterialize: materializer [
	^ materializer nextDictionary: self
]
