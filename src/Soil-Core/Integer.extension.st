Extension { #name : #Integer }

{ #category : #'*Soil-Core' }
Integer >> soilBasicSerialize: serializer [

	serializer nextPutInteger: self
]

{ #category : #'*Soil-Core' }
Integer >> soilSerialize: serializer [
	"Small Integers are immediate objects, no registration needed"
	self isLarge ifTrue: [ (serializer register: self) ifTrue: [^self] ].
	self soilBasicSerialize: serializer
]
