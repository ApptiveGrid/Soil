Extension { #name : #DoubleWordLayout }

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	aBehaviorDescription compatibilityCheck: object class classLayout.
	materializer registerObject: object.

	1 to: basicSize do: [:i | object basicAt: i put: materializer nextLengthEncodedInteger].
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize |
	description := self soilSerializeBehaviorDescription: anObject with: serializer.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i |
		serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
