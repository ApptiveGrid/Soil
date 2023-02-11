Extension { #name : #OrderedCollection }

{ #category : #'*Soil-Serializer' }
OrderedCollection >> addLastAndReturnIndex: newObject [
	"Add newObject to the end of the receiver. Answer newObject."

	lastIndex = array size ifTrue: [self makeRoomAtLast].
	lastIndex := lastIndex + 1.
	array at: lastIndex put: newObject.
	^lastIndex
]

{ #category : #'*Soil-Serializer' }
OrderedCollection >> soilBasicSerialize: serializer [
	self class == OrderedCollection ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutOrderedCollection: self
]

{ #category : #'*Soil-Serializer' }
OrderedCollection class >> soilMaterialize: materializer [

	^ materializer nextOrderedCollection: self
]
