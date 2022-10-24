Extension { #name : #DoubleWordLayout }

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo instSize |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo name.

	instSize := anObject basicSize.
	serializer nextPutLengthEncodedInteger: instSize.
	1 to: instSize do: [:i | serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
