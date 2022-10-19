Extension { #name : #ByteSymbol }

{ #category : #'*Soil-Core' }
ByteSymbol >> soilBasicSerialize: serializer [

	serializer nextPutSymbol: self
]

{ #category : #'*Soil-Core' }
ByteSymbol class >> soilMaterialize: materializer [

	^ materializer nextSymbol
]

{ #category : #'*Soil-Core' }
ByteSymbol >> soilSerialize: serializer [
	"Symbols are created by #asSymbol, thus we do not care that we store them multiple times,
	if the Symbol is larger than an inernal reference, we might waste space (most symbols are small)"
	
	self soilBasicSerialize: serializer
]
