Extension { #name : #EphemeronLayout }

{ #category : #'*Soil-Core' }
EphemeronLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize instSize|

	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	
	materializer registerObject: object.
	instSize := object class soilPersistentInstVars size.
	1 to: instSize do: [:i | object instVarAt: i put: (materializer nextSoilObject) ].
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	object soilMaterialized: materializer.
	^ object
]
