Extension { #name : #DoubleByteLayout }

{ #category : #'*Soil-Core' }
DoubleByteLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object basicSize |
	 object := objectClass basicNew: (basicSize := serializer nextLengthEncodedInteger).
	serializer registerObject: object.
	
	serializer stream readInto: object startingAt: 1 count: basicSize.
	^object

]

{ #category : #'*Soil-Core' }
DoubleByteLayout >> soilBasicSerialize: anObject with: serializer [
	| description |
	description := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: description objectId index.
	
	serializer nextPutLengthEncodedInteger: anObject basicSize.
	1 to: anObject basicSize do: [:i |
		serializer nextPutByte: (anObject at: i)].
]
