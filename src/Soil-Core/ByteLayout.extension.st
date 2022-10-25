Extension { #name : #ByteLayout }

{ #category : #'*Soil-Core' }
ByteLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo instSize |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo name.

	instSize := anObject basicSize.
	serializer nextPutLengthEncodedInteger: instSize.
	serializer nextPutBytesFrom: anObject
]
