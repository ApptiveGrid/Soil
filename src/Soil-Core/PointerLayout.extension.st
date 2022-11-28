Extension { #name : #PointerLayout }

{ #category : #'*Soil-Core' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	|  description |
	description := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: description objectId index.
	
	description instVarIndexes do: [:i | (anObject instVarAt: i) soilSerialize: serializer ].
]
