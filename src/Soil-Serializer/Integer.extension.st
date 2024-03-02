Extension { #name : #Integer }

{ #category : #'*Soil-Serializer' }
Integer >> soilBasicSerialize: serializer [

	serializer nextPutInteger: self
]

{ #category : #'*Soil-Serializer' }
Integer class >> soilMaterialize: materializer [ 
	^ materializer nextSoilObject 
]

{ #category : #'*Soil-Serializer' }
Integer >> soilSerialize: serializer [
	"Small Integers are immediate objects, no registration needed"
	self isImmediateObject ifTrue: [ ^ self soilBasicSerialize: serializer ].
	super soilSerialize: serializer
]
