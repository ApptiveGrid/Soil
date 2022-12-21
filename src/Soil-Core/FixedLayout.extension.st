Extension { #name : #FixedLayout }

{ #category : #'*Soil-Core' }
FixedLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object instSize|
	object := aBehaviorDescription objectClass basicNew.
	materializer registerObject: object.


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
	
	object soilMaterialized: materializer.
	^ object
]
