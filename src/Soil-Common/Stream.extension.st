Extension { #name : #Stream }

{ #category : #'*Soil-Common' }
Stream >> soilNextBytesPutAll: aCollection [
	"Append the bytes of aCollection to the sequence of bytes accessible 
	by the receiver. Answer aCollection."

	^self nextPutAll: aCollection
]
