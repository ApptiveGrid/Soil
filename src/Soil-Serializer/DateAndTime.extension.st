Extension { #name : #DateAndTime }

{ #category : #'*Soil-Serializer' }
DateAndTime >> soilBasicSerialize: serializer [
	self class == DateAndTime ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutDateAndTime: self
]

{ #category : #'*Soil-Serializer' }
DateAndTime class >> soilMaterialize: materializer [ 
	^ materializer nextDateAndTime
]
