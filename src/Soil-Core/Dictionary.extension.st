Extension { #name : #Dictionary }

{ #category : #'*Soil-Core' }
Dictionary >> soilBasicSerialize: serializer [
	self class == Dictionary ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutDictionary: self
]

{ #category : #'*Soil-Core' }
Dictionary class >> soilMaterialize: materializer [
	^ materializer nextDictionary: self
]
