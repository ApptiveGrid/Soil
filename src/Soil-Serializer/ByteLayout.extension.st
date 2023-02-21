Extension { #name : #ByteLayout }

{ #category : #'*Soil-Serializer' }
ByteLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.

	materializer stream readInto: object startingAt: 1 count: basicSize.
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Serializer' }
ByteLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize |
	description := serializer serializeBehaviorDescriptionFor: anObject.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i |
		serializer nextPutByte: (anObject at: i)]
]
