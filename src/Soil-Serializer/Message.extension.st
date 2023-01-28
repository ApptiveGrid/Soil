Extension { #name : #Message }

{ #category : #'*Soil-Serializer' }
Message >> soilBasicSerialize: serializer [ 
	
	serializer nextPutMessage: self
]

{ #category : #'*Soil-Serializer' }
Message class >> soilMaterialize: materializer [ 
	
	^ materializer nextMessage: self
]
