Extension { #name : #DoubleWordLayout }

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicMaterialize: aBehaviorDescription with: materializer [
	| object basicSize |
	object := aBehaviorDescription objectClass basicNew: (basicSize := materializer nextLengthEncodedInteger).
	materializer registerObject: object.
	
	1 to: basicSize do: [:i | object basicAt: i put: materializer nextLengthEncodedInteger].
	^object
]

{ #category : #'*Soil-Core' }
DoubleWordLayout >> soilBasicSerialize: anObject with: serializer [
	| instSize description |
	description := serializer behaviorDescriptionFor: anObject class.
	serializer 
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description isMeta 
			ifTrue: [ 0 ]
			ifFalse: [ serializer referenceIndexOf: description]).

	instSize := anObject basicSize.
	serializer nextPutLengthEncodedInteger: instSize.
	1 to: instSize do: [:i | serializer nextPutLengthEncodedInteger: (anObject basicAt: i)]
]
