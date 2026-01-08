Extension { #name : #PointerLayout }

{ #category : #'*Soil-Serializer' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	| description class |
	description := serializer serializeBehaviorDescriptionFor: anObject.
	class := anObject class.

	(class soilTransientInstVars size == 0) 
		ifTrue: [1 to: class instSize do: [:index | (anObject instVarAt: index)  theNonSoilProxy soilSerialize: serializer] ]
		ifFalse: [description instVarNames do: [:ivarName | ((class slotNamed: ivarName) read: anObject) theNonSoilProxy soilSerialize: serializer ] ]
]

{ #category : #'*Soil-Serializer' }
PointerLayout >> updateIvars: aBehaviorDescription with: materializer for: object [
	
	aBehaviorDescription isCurrent
		ifTrue: [
				aBehaviorDescription instVarNames do: [:instVar | 
					(object class slotNamed: instVar) write: materializer nextSoilObject to: object ]]
		ifFalse: [
			| versions |
			versions := materializer behaviorVersionsUpTo: aBehaviorDescription.
			versions last instVarNames do: [ :instVar | 
				(versions allSatisfy: [ :version | version instVarNames includes: instVar ]) 
					ifTrue: [ (object class slotNamed: instVar) write: materializer nextSoilObject to: object ]
					ifFalse: [ materializer nextSoilObject "read but ignore"  ] ] ]
]
