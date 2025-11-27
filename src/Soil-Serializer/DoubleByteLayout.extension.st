Extension { #name : #DoubleByteLayout }

{ #category : #'*Soil-Serializer' }
DoubleByteLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.

	materializer stream readInto: object startingAt: 1 count: basicSize.
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Serializer' }
DoubleByteLayout >> soilBasicSerialize: anObject with: serializer [
	| basicSize |
	basicSize := anObject basicSize.
	
	serializer 
		serializeBehaviorDescriptionFor: anObject;
		nextPutLengthEncodedInteger: basicSize.
		
	1 to: basicSize do: [:i |
		serializer nextPutByte: (anObject at: i)]
]
