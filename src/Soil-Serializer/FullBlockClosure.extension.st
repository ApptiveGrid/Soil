Extension { #name : #FullBlockClosure }

{ #category : #'*Soil-Serializer' }
FullBlockClosure >> soilSerialize: serializer [
	"Not stored, thus no registration needed"
	serializer notSupportedError: self
]
