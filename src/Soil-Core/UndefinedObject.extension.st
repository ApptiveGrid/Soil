Extension { #name : #UndefinedObject }

{ #category : #'*Soil-Core' }
UndefinedObject >> soilSerialize: serializer [ 
	serializer nextPutNil: self
]
