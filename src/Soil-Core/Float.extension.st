Extension { #name : #Float }

{ #category : #'*Soil-Core' }
Float >> soilBasicSerialize: serializer [ 
	serializer nextPutFloat: self
]

{ #category : #'*Soil-Core' }
Float class >> soilMaterialize: materializer [ 
	^ materializer nextFloat: self
]

{ #category : #'*Soil-Core' }
Float >> soilSerialize: serializer [
	"SmallFlots are immediate objects, no registration needed"
	self isImmediateObject ifTrue: [ ^ self soilBasicSerialize: serializer ].
	super soilSerialize: serializer
]
