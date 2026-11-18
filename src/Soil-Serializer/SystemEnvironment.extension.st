Extension { #name : #SystemEnvironment }

{ #category : #'*Soil-Serializer' }
SystemEnvironment >> soilBasicSerialize: serializer [

	serializer nextPutSystemDictionary: self
]

{ #category : #'*Soil-Serializer' }
SystemEnvironment >> soilSerialize: serializer [
	"registration not needed, as we always return the current Smalltalk globals value on read"
	self soilBasicSerialize: serializer
]
