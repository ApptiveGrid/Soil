Extension { #name : #Date }

{ #category : #'*Soil-Serializer' }
Date >> soilBasicSerialize: serializer [
	self class == Date ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutDate: self
]

{ #category : #'*Soil-Serializer' }
Date class >> soilMaterialize: materializer [
	^ materializer nextDate: self
]
