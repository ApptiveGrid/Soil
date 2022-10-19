Extension { #name : #Process }

{ #category : #'*Soil-Core' }
Process >> soilSerialize: serializer [
	"Not stored, thus no registration needed"
	serializer notSupportedError: self
]
