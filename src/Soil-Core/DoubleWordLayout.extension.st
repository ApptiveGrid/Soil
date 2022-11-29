Extension { #name : #DoubleWordLayout }

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object basicSize |
	object := objectClass basicNew: (basicSize := serializer nextLengthEncodedInteger).
	serializer registerObject: object.
	
	1 to: basicSize do: [:i | object basicAt: i put: serializer nextLengthEncodedInteger].
	^object
]

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicSerialize: anObject with: serializer [
	| instSize description |
	description := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: description objectId index.

	instSize := anObject basicSize.
	serializer nextPutLengthEncodedInteger: instSize.
	1 to: instSize do: [:i | serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
