Extension { #name : #UndefinedObject }

{ #category : #'*Soil-Serializer' }
UndefinedObject >> soilBasicSerialize: serializer [
	serializer nextPutNil: self
]

{ #category : #'*Soil-Serializer' }
UndefinedObject class >> soilMaterialize: materializer [
	^ nil
]

{ #category : #'*Soil-Serializer' }
UndefinedObject >> soilSerialize: serializer [
	self soilBasicSerialize: serializer
]
