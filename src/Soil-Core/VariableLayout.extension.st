Extension { #name : #VariableLayout }

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object basicSize instSize|

	object := objectClass basicNew: (basicSize := serializer nextLengthEncodedInteger).
	
	serializer registerObject: object.
	instSize := object class soilPersistentInstVars size.
	1 to: instSize do: [:i | object instVarAt: i put: (serializer nextSoilObject) ].
	1 to: basicSize do: [:i | object basicAt: i put: serializer nextSoilObject ].
	object soilMaterialized: serializer.
	^ object
]

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicSerialize: anObject with: serializer [
	| basicSize |
	super soilBasicSerialize: anObject with: serializer.
	
	basicSize := anObject basicSize.
	
	serializer nextPutLengthEncodedInteger: basicSize.
	1 to: basicSize do: [:i | 
		(anObject basicAt: i) soilSerialize: serializer ]
]
