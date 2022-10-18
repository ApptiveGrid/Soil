Extension { #name : #Fraction }

{ #category : #'*Soil-Core' }
Fraction >> soilBasicSerialize: serializer [
	self class == Fraction ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutFraction: self
]
