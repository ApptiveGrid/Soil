Extension { #name : #PointerLayout }

{ #category : #'*Soil-Serializer' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	| description class |
	description := serializer serializeBehaviorDescriptionFor: anObject.
	class := anObject class.

	class hasSoilTransientInstVars 
		ifFalse: [1 to: class instSize do: [:index | (anObject instVarAt: index)  theNonSoilProxy soilSerialize: serializer] ]
		ifTrue: [description instVarNames do: [:ivarName | ((class slotNamed: ivarName) read: anObject) theNonSoilProxy soilSerialize: serializer ] ]
]

{ #category : #'*Soil-Serializer' }
PointerLayout >> updateIvars: aBehaviorDescription with: materializer for: object [
	| class |
	class := object class.
	aBehaviorDescription isCurrent
		ifTrue: [
					class hasSoilTransientInstVars 
						ifFalse: [1 to: class instSize do: [:index | object instVarAt: index put: materializer nextSoilObject ] ] 
						ifTrue:[ aBehaviorDescription instVarNames do: [:instVar | 
					(class slotNamed: instVar) write: materializer nextSoilObject to: object ]]]
		ifFalse: [
			| versions |
			versions := materializer behaviorVersionsUpTo: aBehaviorDescription.
			versions last instVarNames do: [ :instVar | 
				(versions allSatisfy: [ :version | version instVarNames includes: instVar ]) 
					ifTrue: [ (class slotNamed: instVar) write: materializer nextSoilObject to: object ]
					ifFalse: [ materializer nextSoilObject "read but ignore"  ] ] ]
]
