Extension { #name : #Array }

{ #category : #'*Soil-Core' }
Array >> soilBasicSerialize: serializer [
	self class == Array ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutArray: self
]

{ #category : #'*Soil-Core' }
Array class >> soilMaterialize: materializer [

	^ materializer nextArray: self
]
