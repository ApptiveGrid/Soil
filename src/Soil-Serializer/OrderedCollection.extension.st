Extension { #name : #OrderedCollection }

{ #category : #'*Soil-Serializer' }
OrderedCollection >> soilBasicSerialize: serializer [
	self class == OrderedCollection ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutOrderedCollection: self
]

{ #category : #'*Soil-Serializer' }
OrderedCollection class >> soilMaterialize: materializer [

	^ materializer nextOrderedCollection: self
]
