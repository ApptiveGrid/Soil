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
	| description |
	description := serializer behaviorDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description isMeta 
			ifTrue: [ 0 ]
			ifFalse: [ serializer referenceIndexOf: description]).
	
	serializer nextPutLengthEncodedInteger: anObject basicSize.
	1 to: anObject basicSize do: [:i |
		serializer nextPutByte: (anObject at: i)].
]
