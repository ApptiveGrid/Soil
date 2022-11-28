Extension { #name : #Object }

{ #category : #'*Soil-Core' }
Object >> soilBasicSerialize: serializer [
	"Delegate serialization to the class layout"
	self class classLayout soilBasicSerialize: self with: serializer
]

{ #category : #'*Soil-Core' }
Object >> soilLoadedIn: aTransaction [ 

]

{ #category : #'*Soil-Core' }
Object >> soilMaterialize: materializer [
	^ self
]

{ #category : #'*Soil-Core' }
Object >> soilMaterialized: materializer [
]

{ #category : #'*Soil-Core' }
Object class >> soilPersistentInstVars [
	^ self allInstVarNames difference: self soilTransientInstVars 
]

{ #category : #'*Soil-Core' }
Object >> soilSerialize: aSoilSerializer [ 
	aSoilSerializer 
		registerObject: self 
		ifAbsent: [ self soilBasicSerialize: aSoilSerializer ].
	
]
