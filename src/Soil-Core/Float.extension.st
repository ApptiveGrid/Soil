Extension { #name : #Float }

{ #category : #'*Soil-Core' }
Float class >> soilMaterialize: materializer [ 
	^ materializer nextSmallFloat64: self
]
