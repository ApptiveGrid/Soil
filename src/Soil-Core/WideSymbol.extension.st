Extension { #name : #WideSymbol }

{ #category : #'*Soil-Core' }
WideSymbol >> soilBasicSerialize: serializer [

	serializer nextPutWideSymbol: self
]

{ #category : #'*Soil-Core' }
WideSymbol class >> soilMaterialize: materializer [

	^ materializer nextWideSymbol
]

{ #category : #'*Soil-Core' }
WideSymbol >> soilSerialize: serializer [
	"Symbols are created by #asSymbol, thus we do not care that we store them multiple times,
	if the Symbol is larger than an inernal reference, we might waste space (most symbols are small)"
	
	self soilBasicSerialize: serializer
]
