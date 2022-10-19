Extension { #name : #SmallFloat64 }

{ #category : #'*Soil-Core' }
SmallFloat64 >> soilBasicSerialize: serializer [ 
	serializer nextPutSmallFloat64: self
]

{ #category : #'*Soil-Core' }
SmallFloat64 class >> soilMaterialize: materializer [ 
	^ materializer nextSmallFloat64: self
]

{ #category : #'*Soil-Core' }
SmallFloat64 >> soilSerialize: serializer [
	"immediate object, no registration needed"
	self soilBasicSerialize: serializer
]
