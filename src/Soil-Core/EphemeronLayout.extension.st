Extension { #name : #EphemeronLayout }

{ #category : #'*Soil-Core' }
EphemeronLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |

	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	
	materializer registerObject: object.
	
	self updateIvars: aBehaviorDescription with: materializer for: object.
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	^object soilMaterialized: materializer
]
