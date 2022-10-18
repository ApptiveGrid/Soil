Extension { #name : #Date }

{ #category : #'*Soil-Core' }
Date >> soilBasicSerialize: serializer [
	self class == Date ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutDate: self
]

{ #category : #'*Soil-Core' }
Date class >> soilMaterialize: materializer [ 
	^ materializer nextDate: self
]
