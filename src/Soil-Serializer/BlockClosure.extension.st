Extension { #name : #BlockClosure }

{ #category : #'*Soil-Serializer' }
BlockClosure >> soilMaterialize: materializer [
	^ self value: materializer
]
