Extension { #name : #EphemeronLayout }

{ #category : #'*Soil-Serializer' }
EphemeronLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |

	object := aBehaviorDescription basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.

	self updateIvars: aBehaviorDescription with: materializer for: object.
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Serializer' }
EphemeronLayout >> soilBasicSerialize: anObject with: serializer [
	| description class basicSize|

	description := serializer serializeBehaviorDescriptionFor: anObject.
	class := anObject class.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	(class soilTransientInstVars size == 0) 
		ifTrue: [1 to: class instSize do: [:index | (anObject instVarAt: index)  theNonSoilProxy soilSerialize: serializer] ]
		ifFalse: [description instVarNames do: [:ivarName | ((class slotNamed: ivarName) read: anObject) theNonSoilProxy soilSerialize: serializer ] ].
	1 to: basicSize do: [:i | (anObject basicAt: i) soilSerialize: serializer ]
]
