Extension { #name : #DoubleWordLayout }

{ #category : #'*Soil-Serializer' }
DoubleWordLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.

	1 to: basicSize do: [:i | object basicAt: i put: materializer nextLengthEncodedInteger].
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Serializer' }
DoubleWordLayout >> soilBasicSerialize: anObject with: serializer [
	| basicSize |
	basicSize := anObject basicSize.
	serializer 
		serializeBehaviorDescriptionFor: anObject;
		nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i |
		serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
