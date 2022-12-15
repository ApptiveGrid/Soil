Extension { #name : #ByteLayout }

{ #category : #'*Soil-Core' }
ByteLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object basicSize |
	 object := objectClass basicNew: (basicSize := serializer nextLengthEncodedInteger).
	serializer registerObject: object.
	
	serializer stream readInto: object startingAt: 1 count: basicSize.
	^object

]

{ #category : #'*Soil-Core' }
ByteLayout >> soilBasicSerialize: anObject with: serializer [
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
