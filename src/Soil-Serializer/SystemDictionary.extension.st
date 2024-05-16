Extension { #name : 'SystemDictionary' }

{ #category : '*Soil-Serializer' }
SystemDictionary >> soilBasicSerialize: serializer [

	serializer nextPutSystemDictionary: self
]

{ #category : '*Soil-Serializer' }
SystemDictionary >> soilSerialize: serializer [
	"registration not needed, as we always return the current Smalltalk globals value on read"
	self soilBasicSerialize: serializer
]
