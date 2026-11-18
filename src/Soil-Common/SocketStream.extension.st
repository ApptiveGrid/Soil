Extension { #name : #SocketStream }

{ #category : #'*Soil-Common' }
SocketStream >> soilNextBytesPutAll: aCollection [
	"Append the bytes of aCollection to the sequence of bytes accessible 
	by the receiver. Answer aCollection."

	^ self nextPutAll: aCollection
]
