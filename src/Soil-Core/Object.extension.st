Extension { #name : #Object }

{ #category : #'*Soil-Core' }
Object >> soilBasicSerialize: serializer [ 
	| classInfo instSize |
	classInfo := serializer classDescriptionFor: self class.
	serializer 
		nextPutObjectType;
		nextPutByte: classInfo classId.
	 
	self flag: #question.
	"How many layouts there are??"
	classInfo isVariable ifTrue: [ serializer nextPutLengthEncodedInteger: self basicSize ].
	"classInfo isBytes ifTrue: [ self halt ]."
	classInfo isBytes ifFalse: [
		classInfo instVarIndexes do: [:i | (self instVarAt: i) soilSerialize: serializer ].
		instSize := self class instSize.
		"on variable sized objects size > instVars"
		instSize + 1 to: instSize + self basicSize do: [:i | 
			(self instVarAt: i) soilSerialize: serializer ].
		^self].
]

{ #category : #'*Soil-Core' }
Object >> soilLoadedIn: aTransaction [ 

]

{ #category : #'*Soil-Core' }
Object class >> soilMaterialize: aSoilMaterializer [ 
	self shouldBeImplemented.
]

{ #category : #'*Soil-Core' }
Object >> soilSerialize: aSoilSerializer [ 
	aSoilSerializer 
		registerObject: self 
		ifAbsent: [ self soilBasicSerialize: aSoilSerializer ].
	
]
