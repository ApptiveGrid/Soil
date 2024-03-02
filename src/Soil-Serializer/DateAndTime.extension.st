Extension { #name : #DateAndTime }

{ #category : #'*Soil-Serializer' }
DateAndTime >> soilBasicSerialize: serializer [
	self class == DateAndTime ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutDateAndTime: self
]
