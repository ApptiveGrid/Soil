Extension { #name : #VariableLayout }

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicSerialize: anObject with: serializer [
	| classInfo instSize |
	classInfo := serializer classDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		basicNextPutString: classInfo name.
	 serializer nextPutLengthEncodedInteger: anObject basicSize.
	
	classInfo instVarIndexes do: [:i | (anObject instVarAt: i) soilSerialize: serializer ].
		instSize := anObject class instSize.
		"on variable sized objects size > instVars"
		instSize + 1 to: instSize + anObject basicSize do: [:i | 
		(anObject instVarAt: i) soilSerialize: serializer ]
]
