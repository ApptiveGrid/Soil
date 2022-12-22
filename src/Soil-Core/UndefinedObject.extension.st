Extension { #name : #UndefinedObject }

{ #category : #'*Soil-Core' }
UndefinedObject >> soilBasicSerialize: serializer [ 
	serializer nextPutNil: self
]

{ #category : #'*Soil-Core' }
UndefinedObject class >> soilMaterialize: materializer [
	^ nil
]

{ #category : #'*Soil-Core' }
UndefinedObject >> soilSerialize: serializer [ 
	self soilBasicSerialize: serializer
]
