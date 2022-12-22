Extension { #name : #String }

{ #category : #'*Soil-Core' }
String >> asSkipListKeyOfSize: anInteger [ 
	^ self asByteArray asSkipListKeyOfSize: anInteger
]

{ #category : #'*Soil-Core' }
String >> soilBasicSerialize: serializer [
	serializer nextPutString: self
]

{ #category : #'*Soil-Core' }
String class >> soilMaterialize: materializer [

	^ materializer nextString
]
