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
	
	description instVarNames do: [:ivarName | (anObject instVarNamed: ivarName) soilSerialize: serializer ].
]

{ #category : #'*Soil-Core' }
PointerLayout >> updateIvars: aBehaviorDescription with: materializer for: object [
	
	aBehaviorDescription isCurrent
		ifTrue: [
				aBehaviorDescription instVarNames do: [:instVar | 
					object instVarNamed: instVar put: (materializer nextSoilObject) ]]
		ifFalse: [
			| versions |
			versions := materializer behaviorVersionsUpTo: aBehaviorDescription.
			versions last instVarNames do: [ :instVar | 
				(versions allSatisfy: [ :version | version instVarNames includes: instVar ]) ifTrue: [ 
					 object instVarNamed: instVar put: materializer nextSoilObject ] ] ]
]
