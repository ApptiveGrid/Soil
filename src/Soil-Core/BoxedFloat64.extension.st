Extension { #name : #BoxedFloat64 }

{ #category : #'*Soil-Core' }
BoxedFloat64 >> soilBasicSerialize: serializer [ 
	serializer nextPutBoxedFloat64: self
]

{ #category : #'*Soil-Core' }
BoxedFloat64 class >> soilMaterialize: materializer [ 
	^ materializer nextBoxedFloat64: self
]

{ #category : #'*Soil-Core' }
BoxedFloat64 >> soilSerialize: serializer [ 
	self flag: #TODO. "Explain why we do not register Boxed Floats?"
	self soilBasicSerialize: serializer
]
