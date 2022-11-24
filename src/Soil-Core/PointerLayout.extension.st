Extension { #name : #PointerLayout }

{ #category : #'*Soil-Core' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo classIdentifier;
		basicNextPutString: classInfo versionIdentifier.
	
	classInfo instVarIndexes do: [:i | (anObject instVarAt: i) soilSerialize: serializer ].
]
