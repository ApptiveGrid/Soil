Extension { #name : #Array }

{ #category : #'*Soil-Serializer' }
Array >> soilBasicSerialize: serializer [
	self class == Array ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutArray: self
]

{ #category : #'*Soil-Serializer' }
Array class >> soilMaterialize: materializer [

	^ materializer nextArray: self
]
