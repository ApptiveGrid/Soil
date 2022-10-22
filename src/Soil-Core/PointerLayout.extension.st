Extension { #name : #PointerLayout }

{ #category : #'*Soil-Core' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo instSize |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo name.
	
	classInfo instVarIndexes do: [:i | (anObject instVarAt: i) soilSerialize: serializer ].
		instSize := anObject class instSize.
		"on variable sized objects size > instVars"
		instSize + 1 to: instSize + anObject basicSize do: [:i | 
		(anObject instVarAt: i) soilSerialize: serializer ]
]
