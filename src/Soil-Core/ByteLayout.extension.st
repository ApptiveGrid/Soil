Extension { #name : #ByteLayout }

{ #category : #'*Soil-Core' }
ByteLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo name.

	serializer nextPutLengthEncodedInteger: anObject basicSize.
	serializer nextPutBytesFrom: anObject len: anObject basicSize
]
