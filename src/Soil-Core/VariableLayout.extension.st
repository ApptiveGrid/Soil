Extension { #name : #VariableLayout }

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicSerialize: anObject with: serializer [
	| instSize |
	super soilBasicSerialize: anObject with: serializer.
	
	serializer nextPutLengthEncodedInteger: anObject basicSize.
	"on variable sized objects size > instVars"
	instSize := anObject class instSize.
	instSize + 1 to: instSize + anObject basicSize do: [:i | 
	(anObject basicAt: i) soilSerialize: serializer ]
]
