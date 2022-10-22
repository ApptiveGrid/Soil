Extension { #name : #DoubleWordLayout }

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo name.

	serializer nextPutLengthEncodedInteger: anObject basicSize.
	1 to: anObject basicSize do: [:i | serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
