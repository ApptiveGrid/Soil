Extension { #name : #Object }

{ #category : #'*Soil-Serializer' }
Object >> soilBasicSerialize: serializer [
	"Delegate serialization to the class layout"
	self class classLayout soilBasicSerialize: self with: serializer
]

{ #category : #'*Soil-Serializer' }
Object >> soilBasicSerializeWithRegistry: aRegistry [
	^ ByteArray streamContents: [:stream |
		SoilSerializer new  
			stream: stream ;
			externalObjectRegistry: aRegistry;
			serialize: self ]
]

{ #category : #'*Soil-Serializer' }
Object >> soilLoadedIn: aTransaction [ 

]

{ #category : #'*Soil-Serializer' }
Object >> soilMaterializationReplacement [
	^ self
]

{ #category : #'*Soil-Serializer' }
Object >> soilMaterialize: materializer [
	^ self 
]

{ #category : #'*Soil-Serializer' }
Object >> soilMaterialized: materializer [
]

{ #category : #'*Soil-Serializer' }
Object class >> soilPersistentInstVars [
	"return the persistent var names of the hierachy"
	^ self allInstVarNames difference: self soilTransientInstVars 
]

{ #category : #'*Soil-Serializer' }
Object >> soilSerializationReplacement [
	^ self
]

{ #category : #'*Soil-Serializer' }
Object >> soilSerialize [
	^ ByteArray streamContents: [ :stream |
		self soilSerializeOn: stream ]
	
]

{ #category : #'*Soil-Serializer' }
Object >> soilSerialize: aSoilSerializer [ 
	| object |
	object := self soilSerializationReplacement.
	aSoilSerializer 
		registerObject: object 
		ifAbsent: [ object soilBasicSerialize: aSoilSerializer ].
	
]

{ #category : #'*Soil-Serializer' }
Object >> soilSerializeOn: aStream [ 
	| registry bytes |
	registry := SoilStandaloneObjectRegistry new.
	bytes := self soilBasicSerializeWithRegistry: registry.
	registry writeOn: aStream.
	aStream nextPutAll: bytes
]

{ #category : #'*Soil-Serializer' }
Object >> soilIsWrittenByValue [
	"whether the serializer writes the receiver where it is referenced instead of as a
	reference to a record of its own - an immediate object, a symbol, a class, true,
	false and nil. Made a cluster root, such an object gets a record nothing can point at.

	The system objects whose #soilSerialize: does not register either - Smalltalk,
	Smalltalk globals, Processor - are left out: nobody keeps them as a value"
	^ self isImmediateObject
]
