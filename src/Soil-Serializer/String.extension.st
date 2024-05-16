Extension { #name : #String }

{ #category : #'*Soil-Serializer' }
String >> soilBasicSerialize: serializer [
	serializer nextPutString: self
]

{ #category : #'*Soil-Serializer' }
String class >> soilMaterialize: materializer [

	^ materializer nextString
]
