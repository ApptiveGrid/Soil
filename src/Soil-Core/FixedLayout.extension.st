Extension { #name : #FixedLayout }

{ #category : #'*Soil-Core' }
FixedLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object |
	object := aBehaviorDescription objectClass basicNew.
	materializer registerObject: object.
	
	self updateIvars: aBehaviorDescription with: materializer for: object.
	^ object soilMaterialized: materializer
]
