Extension { #name : #MessageSend }

{ #category : #'*Soil-Serializer' }
MessageSend >> soilBasicSerialize: serializer [ 
	
	serializer nextPutMessageSend: self
]

{ #category : #'*Soil-Serializer' }
MessageSend class >> soilMaterialize: materializer [ 

	^ materializer nextMessageSend: self
]
