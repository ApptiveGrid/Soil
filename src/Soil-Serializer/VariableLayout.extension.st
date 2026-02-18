Extension { #name : #VariableLayout }

{ #category : #'*Soil-Serializer' }
VariableLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |

	"if we read an object that was stored with a fixed layout, there is no size written"
	basicSize := aBehaviorDescription isFixedLayout
		ifTrue: [ 0 ]
		ifFalse: [ materializer nextLengthEncodedInteger ].
	object := aBehaviorDescription basicNew: basicSize.
	materializer registerObject: object.

	self updateIvars: aBehaviorDescription with: materializer for: object.
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextSoilObject ].
	^ object
]

{ #category : #'*Soil-Serializer' }
VariableLayout >> soilBasicSerialize: anObject with: serializer [
	| description class basicSize|

	description := serializer serializeBehaviorDescriptionFor: anObject.
	class := anObject class.
	basicSize := anObject basicSize.

	serializer nextPutLengthEncodedInteger: basicSize.
	class hasSoilTransientInstVars 
		ifFalse: [1 to: class instSize do: [:index | (anObject instVarAt: index)  theNonSoilProxy soilSerialize: serializer] ]
		ifTrue: [description instVarNames do: [:ivarName | ((class slotNamed: ivarName) read: anObject) theNonSoilProxy soilSerialize: serializer ] ].
	1 to: basicSize do: [:i | (anObject basicAt: i) soilSerialize: serializer ]
]
