Extension { #name : #PointerLayout }

{ #category : #'*Soil-Serializer' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	| description |
	description := self soilSerializeBehaviorDescription: anObject with: serializer.

	description instVarNames do: [:ivarName | (anObject instVarNamed: ivarName) soilSerialize: serializer ]
]

{ #category : #'*Soil-Serializer' }
PointerLayout >> updateIvars: aBehaviorDescription with: materializer for: object [

	aBehaviorDescription isCurrent
		ifTrue: [
				aBehaviorDescription instVarNames do: [:instVar |
					object instVarNamed: instVar put: (materializer nextSoilObject) ]]
		ifFalse: [
			| versions |
			versions := materializer behaviorVersionsUpTo: aBehaviorDescription.
			versions last instVarNames do: [ :instVar |
				(versions allSatisfy: [ :version | version instVarNames includes: instVar ])
					ifTrue: [  object instVarNamed: instVar put: materializer nextSoilObject ]
					ifFalse: [ materializer nextSoilObject "read but ignore"  ] ] ]
]
