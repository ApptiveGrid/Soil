Extension { #name : #FullBlockClosure }

{ #category : #'*Soil-Core' }
FullBlockClosure >> soilSerialize: serializer [
	"Not stored, thus no registration needed"
	serializer notSupportedError: self
]
