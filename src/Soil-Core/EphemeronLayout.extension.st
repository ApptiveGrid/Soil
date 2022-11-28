Extension { #name : #EphemeronLayout }

{ #category : #'*Soil-Core' }
EphemeronLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object basicSize instSize|

	object := objectClass basicNew: (basicSize := serializer nextLengthEncodedInteger).
	
	serializer registerObject: object.
	instSize := object class soilPersistentInstVars size.
	1 to: instSize do: [:i | object instVarAt: i put: (serializer nextSoilObject) ].
	1 to: basicSize do: [:i | object basicAt: i put: serializer nextSoilObject ].
	object soilMaterialized: serializer.
	^ object
]
