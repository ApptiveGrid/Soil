Extension { #name : #WeakLayout }

{ #category : #'*Soil-Core' }
WeakLayout >> soilBasicMaterialize: objectClass with: serializer [
	| object basicSize instSize|

	object := objectClass basicNew: (basicSize := serializer nextLengthEncodedInteger).
	
	serializer registerObject: object.
	instSize := object class instSize.
	1 to: instSize do: [:i | object instVarAt: i put: (serializer nextSoilObject) ].
	1 to: basicSize do: [:i | object basicAt: i put: serializer nextSoilObject ].
	object soilMaterialized: serializer.
	^ object
]

{ #category : #'*Soil-Core' }
WeakLayout >> soilBasicSerialize: anObject with: serializer [
	| instSize |
	super soilBasicSerialize: anObject with: serializer.
	
	serializer nextPutLengthEncodedInteger: anObject basicSize.
	"on variable sized objects size > instVars"
	instSize := anObject class instSize.
	instSize + 1 to: instSize + anObject basicSize do: [:i | 
	(anObject basicAt: i) soilSerialize: serializer ]
]
