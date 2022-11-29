Extension { #name : #FixedLayout }

{ #category : #'*Soil-Core' }
FixedLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object instSize|
	object := objectClass basicNew.
	serializer registerObject: object.

	instSize := object class soilPersistentInstVars size.
	1 to: instSize do: [:i | object instVarAt: i put: (serializer nextSoilObject) ].
	object soilMaterialized: serializer.
	^ object
]
