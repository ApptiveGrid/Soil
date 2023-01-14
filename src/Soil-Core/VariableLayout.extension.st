Extension { #name : #VariableLayout }

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |

	"if we read an object that was stored with a fixed layout, there is no size written"
	basicSize := aBehaviorDescription isFixedLayout
		ifTrue: [ 0 ]
		ifFalse: [ materializer nextLengthEncodedInteger ].
	object := aBehaviorDescription objectClass basicNew: basicSize.

	materializer registerObject: object.

	self updateIvars: aBehaviorDescription with: materializer for: object.
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicSerialize: anObject with: serializer [
	| description basicSize|

	description := self soilSerializeBehaviorDescription: anObject with: serializer.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	description instVarNames do: [:ivarName | (anObject instVarNamed: ivarName) soilSerialize: serializer ].
	1 to: basicSize do: [:i | (anObject basicAt: i) soilSerialize: serializer ]
]
