Extension { #name : #BlockClosure }

{ #category : #'*Soil-Core' }
BlockClosure >> soilMaterialize: materializer [ 
	^ self value: materializer
]
