Extension { #name : #ByteLayout }

{ #category : #'*Soil-Serializer' }
ByteLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	aBehaviorDescription compatibilityCheck: object class classLayout.

	materializer registerObject: object.

	materializer stream readInto: object startingAt: 1 count: basicSize.
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Serializer' }
ByteLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize |
	description := self soilSerializeBehaviorDescription: anObject with: serializer.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i |
		serializer nextPutByte: (anObject at: i)]
]
