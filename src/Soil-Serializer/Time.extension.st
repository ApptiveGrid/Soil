Extension { #name : 'Time' }

{ #category : '*Soil-Serializer' }
Time >> soilBasicSerialize: serializer [
	self class == Time ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutTime: self
]

{ #category : '*Soil-Serializer' }
Time class >> soilMaterialize: materializer [

	^ materializer nextTime
]
