Extension { #name : #MessageSend }

{ #category : #'*Soil-Core' }
MessageSend >> soilBasicSerialize: serializer [ 
	
	serializer nextPutMessageSend: self
]

{ #category : #'*Soil-Core' }
MessageSend class >> soilMaterialize: materializer [ 

	^ materializer nextMessageSend: self
]
