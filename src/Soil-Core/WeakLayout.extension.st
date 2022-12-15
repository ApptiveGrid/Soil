Extension { #name : #WeakLayout }

{ #category : #'*Soil-Core' }
WeakLayout >> soilBasicMaterialize: objectClass with: serializer [
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
WeakLayout >> soilBasicSerialize: anObject with: serializer [
	|  description basicSize|
	
	description := serializer behaviorDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description isMeta 
			ifTrue: [ 0 ]
			ifFalse: [ serializer referenceIndexOf: description]).


	basicSize := anObject basicSize.
	serializer nextPutLengthEncodedInteger: basicSize.
	
	description instVarIndexes do: [:i | (anObject instVarAt: i) soilSerialize: serializer ].
	1 to: basicSize do: [:i | (anObject basicAt: i) soilSerialize: serializer ]
]
