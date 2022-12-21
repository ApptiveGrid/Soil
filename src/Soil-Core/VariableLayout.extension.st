Extension { #name : #VariableLayout }

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |

	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	
	materializer registerObject: object.
	
	self updateIvars: aBehaviorDescription with: materializer for: object.
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	^object soilMaterialized: materializer
]

{ #category : #'*Soil-Core' }
VariableLayout >> soilBasicSerialize: anObject with: serializer [
	|  description basicSize|
	
	description := serializer behaviorDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description isMeta 
			ifTrue: [ 0 ]
			ifFalse: [ serializer referenceIndexOf: description]).


	basicSize := anObject basicSize.
	serializer nextPutLengthEncodedInteger: basicSize.
	
	description instVarNames do: [:ivarName | (anObject instVarNamed: ivarName) soilSerialize: serializer ].
	1 to: basicSize do: [:i | (anObject basicAt: i) soilSerialize: serializer ]
]
