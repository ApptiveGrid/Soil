Extension { #name : #WeakLayout }

{ #category : #'*Soil-Serializer' }
WeakLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |

	object := aBehaviorDescription basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.

	self updateIvars: aBehaviorDescription with: materializer for: object.
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	^ object soilMaterialized: materializer
]

{ #category : #'*Soil-Serializer' }
WeakLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize|

	description := serializer serializeBehaviorDescriptionFor: anObject.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	description instVarNames do: [:ivarName | (anObject instVarNamed: ivarName) soilSerialize: serializer ].
	1 to: basicSize do: [:i | (anObject basicAt: i) soilSerialize: serializer ]
]
