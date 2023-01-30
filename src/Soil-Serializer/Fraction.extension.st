Extension { #name : #Fraction }

{ #category : #'*Soil-Serializer' }
Fraction >> soilBasicSerialize: serializer [
	(numerator isInteger and: [ numerator isImmediateObject])
		ifFalse: [ ^ super soilBasicSerialize: serializer ].
	(denominator isInteger and: [ denominator isImmediateObject])
		ifFalse: [ ^ super soilBasicSerialize: serializer ].
	self class == Fraction
		ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutFraction: self
]

{ #category : #'*Soil-Serializer' }
Fraction class >> soilMaterialize: materializer [

	^ materializer nextFraction: self
]
