Extension { #name : 'SmalltalkImage' }

{ #category : '*Soil-Serializer' }
SmalltalkImage >> soilBasicSerialize: serializer [

	serializer nextPutSmalltalkImage: self
]

{ #category : '*Soil-Serializer' }
SmalltalkImage >> soilSerialize: serializer [
	"registration not needed, as we always return the current Smalltalk value on read"
	self soilBasicSerialize: serializer
]
