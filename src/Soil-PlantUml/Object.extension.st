Extension { #name : #Object }

{ #category : #'*Soil-PlantUml' }
Object class >> pumlClassOn: aStream [

	aStream lf; nextPutAll: 'class '; nextPutAll: self name asString; nextPut: ${; lf.

	self pumlLocalFieldDefs "pumlAllFieldDefs" do: [ :eachDef |
		self pumlField: eachDef key type: eachDef value on: aStream ].

	aStream nextPut: $}; lf
]

{ #category : #'*Soil-PlantUml' }
Object class >> pumlField: aFieldName type: aTypeName on: aStream [

	aStream nextPutAll: '{field} ', aFieldName, ' : ', aTypeName; lf
]

{ #category : #'*Soil-PlantUml' }
Object class >> pumlLocalFieldDefs [

	^ (self class includesSelector: #pumlFieldDefs)
		ifTrue: [ self pumlFieldDefs ]
		ifFalse: [ {} ]
]
