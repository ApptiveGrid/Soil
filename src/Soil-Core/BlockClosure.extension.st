Extension { #name : #BlockClosure }

{ #category : #'*Soil-Core' }
BlockClosure >> soilMaterialize: materializer [ 
	^ self value: materializer
]

{ #category : #'*Soil-Core' }
BlockClosure >> soilSerialize: serializer [
	"Not stored, thus no registration needed"
	serializer notSupportedError: self
]
