Extension { #name : #ScaledDecimal }

{ #category : #'*Soil-Serializer' }
ScaledDecimal >> soilBasicSerialize: serializer [
	(numerator isInteger and: [ numerator isImmediateObject]) 
		ifFalse: [ ^ super soilBasicSerialize: serializer ].
	(denominator isInteger and: [ denominator isImmediateObject]) 
		ifFalse: [ ^ super soilBasicSerialize: serializer ].
	(scale isInteger and: [ denominator isImmediateObject]) 
		ifFalse: [ ^ super soilBasicSerialize: serializer ].

	self class == ScaledDecimal ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutScaledDecimal: self
]

{ #category : #'*Soil-Serializer' }
ScaledDecimal class >> soilMaterialize: materializer [

	^ materializer nextScaledDecimal: self
]
