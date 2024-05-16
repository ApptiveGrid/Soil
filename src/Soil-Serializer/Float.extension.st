Extension { #name : #Float }

{ #category : #'*Soil-Serializer' }
Float >> soilBasicSerialize: serializer [ 
	serializer nextPutFloat: self
]

{ #category : #'*Soil-Serializer' }
Float class >> soilMaterialize: materializer [ 
	^ materializer nextFloat: self
]

{ #category : #'*Soil-Serializer' }
Float >> soilSerialize: serializer [
	"SmallFloats are immediate objects, no registration needed"
	self isImmediateObject ifTrue: [ ^ self soilBasicSerialize: serializer ].
	super soilSerialize: serializer
]
