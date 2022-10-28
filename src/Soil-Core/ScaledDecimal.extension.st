Extension { #name : #ScaledDecimal }

{ #category : #'*Soil-Core' }
ScaledDecimal >> soilBasicSerialize: serializer [
	self class == ScaledDecimal ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutScaledDecimal: self
]
