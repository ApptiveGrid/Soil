Extension { #name : #DoubleByteLayout }

{ #category : #'*Soil-Core' }
DoubleByteLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.
	
	materializer stream readInto: object startingAt: 1 count: basicSize.
	^object

]

{ #category : #'*Soil-Core' }
DoubleByteLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize |
	description := self soilSerializeBehaviorDescription: anObject with: serializer.
	basicSize := anObject basicSize.
	
	serializer nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i | 
		serializer nextPutByte: (anObject at: i)]
]
