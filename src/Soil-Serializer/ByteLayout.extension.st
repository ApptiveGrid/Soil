Extension { #name : #ByteLayout }

{ #category : #'*Soil-Serializer' }
ByteLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.

	materializer stream readInto: object startingAt: 1 count: basicSize.
	^ object 
]

{ #category : #'*Soil-Serializer' }
ByteLayout >> soilBasicSerialize: anObject with: serializer [
	serializer 
		serializeBehaviorDescriptionFor: anObject;
		nextPutLengthEncodedInteger: anObject basicSize;
		nextPutBytesFrom: anObject
]
