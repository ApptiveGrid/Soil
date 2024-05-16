Extension { #name : 'Process' }

{ #category : '*Soil-Serializer' }
Process >> soilSerialize: serializer [
	"Not stored, thus no registration needed"
	serializer notSupportedError: self
]
