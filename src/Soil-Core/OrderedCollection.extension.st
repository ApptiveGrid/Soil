Extension { #name : #OrderedCollection }

{ #category : #'*Soil-Core' }
OrderedCollection >> soilBasicSerialize: serializer [
	self class == OrderedCollection ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutOrderedCollection: self
]
