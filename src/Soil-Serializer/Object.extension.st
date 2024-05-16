Extension { #name : 'Object' }

{ #category : '*Soil-Serializer' }
Object >> soilBasicSerialize: serializer [
	"Delegate serialization to the class layout"
	self class classLayout soilBasicSerialize: self with: serializer
]

{ #category : '*Soil-Serializer' }
Object >> soilBasicSerializeWithRegistry: aRegistry [
	^ ByteArray streamContents: [:stream |
		SoilSerializer new  
			stream: stream ;
			externalObjectRegistry: aRegistry;
			serialize: self ]
]

{ #category : '*Soil-Serializer' }
Object >> soilLoadedIn: aTransaction [ 

]

{ #category : '*Soil-Serializer' }
Object >> soilMaterialize: materializer [
	^ self
]

{ #category : '*Soil-Serializer' }
Object >> soilMaterialized: materializer [
]

{ #category : '*Soil-Serializer' }
Object class >> soilPersistentInstVars [
	^ self allInstVarNames difference: self soilTransientInstVars 
]

{ #category : '*Soil-Serializer' }
Object >> soilSerialize [
	^ ByteArray streamContents: [ :stream |
		self soilSerializeOn: stream ]
	
]

{ #category : '*Soil-Serializer' }
Object >> soilSerialize: aSoilSerializer [ 
	aSoilSerializer 
		registerObject: self 
		ifAbsent: [ self soilBasicSerialize: aSoilSerializer ].
	
]

{ #category : '*Soil-Serializer' }
Object >> soilSerializeOn: aStream [ 
	| registry bytes |
	registry := SoilStandaloneObjectRegistry new.
	bytes := self soilBasicSerializeWithRegistry: registry.
	registry writeOn: aStream.
	aStream nextPutAll: bytes
]
