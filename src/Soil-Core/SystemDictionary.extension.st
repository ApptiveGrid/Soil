Extension { #name : #SystemDictionary }

{ #category : #'*Soil-Core' }
SystemDictionary >> soilBasicSerialize: serializer [

	serializer nextPutSystemDictionary: self
]

{ #category : #'*Soil-Core' }
SystemDictionary >> soilSerialize: serializer [
	"registration not needed, as we always return the current Smalltalk globals value on read"
	self soilBasicSerialize: serializer
]
