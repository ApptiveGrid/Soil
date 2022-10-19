Extension { #name : #Fraction }

{ #category : #'*Soil-Core' }
Fraction >> soilBasicSerialize: serializer [
	self class == Fraction ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutFraction: self
]

{ #category : #'*Soil-Core' }
Fraction class >> soilMaterialize: materializer [

	^ materializer nextFraction: self
]
