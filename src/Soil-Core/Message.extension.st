Extension { #name : #Message }

{ #category : #'*Soil-Core' }
Message >> soilBasicSerialize: serializer [ 
	
	serializer nextPutMessage: self
]

{ #category : #'*Soil-Core' }
Message class >> soilMaterialize: materializer [ 
	
	^ materializer nextMessage: self
]
