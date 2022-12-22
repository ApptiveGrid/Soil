Extension { #name : #WordLayout }

{ #category : #'*Soil-Core' }
WordLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	 object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.
	
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextLengthEncodedInteger].
	^object
]

{ #category : #'*Soil-Core' }
WordLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize |
	
	description := self soilSerializeBehaviorDescription: anObject with: serializer.
	basicSize := anObject basicSize.
	
	serializer nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i | serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
