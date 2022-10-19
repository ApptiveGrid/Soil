Extension { #name : #Time }

{ #category : #'*Soil-Core' }
Time >> soilBasicSerialize: serializer [
	self class == Time ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutTime: self
]

{ #category : #'*Soil-Core' }
Time class >> soilMaterialize: materializer [

	^ materializer nextTime
]
