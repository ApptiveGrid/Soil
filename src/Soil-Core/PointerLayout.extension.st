Extension { #name : #PointerLayout }

{ #category : #'*Soil-Core' }
PointerLayout >> soilBasicSerialize: anObject with: serializer [
	|  description |
	description := serializer behaviorDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description isMeta 
			ifTrue: [ 0 ]
			ifFalse: [ serializer referenceIndexOf: description]).
	
	description instVarIndexes do: [:i | (anObject instVarAt: i) soilSerialize: serializer ].
]

{ #category : #'*Soil-Core' }
PointerLayout >> updateIvars: aBehaviorDescription with: materializer for: object [
	| instSize |
	instSize := object class soilPersistentInstVars size.
	aBehaviorDescription isCurrent
		ifTrue: [ 
				instSize := object class soilPersistentInstVars size.
				1 to: instSize do: [:i | object instVarAt: i put: (materializer nextSoilObject) ]]
		ifFalse: [
			| versions |
			versions := materializer behaviorVersionsUpTo: aBehaviorDescription.
			versions last instVarNames do: [ :instVar | | value |
				value := materializer nextSoilObject.
				(versions allSatisfy: [ :version | version instVarNames includes: instVar ]) ifTrue: [ 
					 object instVarNamed: instVar put: value ] ]
			].
]
