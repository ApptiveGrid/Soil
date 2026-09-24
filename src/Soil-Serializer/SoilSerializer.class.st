Class {
	#name : #SoilSerializer,
	#superclass : #SoilBasicSerializer,
	#instVars : [
		'clusterRoot',
		'transaction',
		'objectIdTable',
		'externalObjectRegistry',
		'soil'
	],
	#category : #'Soil-Serializer-Serializer/Materializer'
}

{ #category : #accessing }
SoilSerializer >> externalObjectRegistry: anObject [

	externalObjectRegistry := anObject
]

{ #category : #initialization }
SoilSerializer >> initialize [ 
	super initialize.
	objectIdTable := SoilObjectTable new
]

{ #category : #writing }
SoilSerializer >> nextPutArray: anArray [ 
	self 
		nextPutByte: TypeCodeArray;
		nextPutLengthEncodedInteger: anArray size.
	1 to: anArray size do: [:i | 
		(anArray at: i) soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutAssociation: anAssociation [ 
	self nextPutByte: TypeCodeAssociation.
	anAssociation key soilSerialize: self.
	anAssociation value soilSerialize: self.
]

{ #category : #writing }
SoilSerializer >> nextPutClass: aClass [ 

	self 
		nextPutByte: TypeCodeClass; 
		basicNextPutString: aClass name asString
]

{ #category : #writing }
SoilSerializer >> nextPutCompiledBlock: aCompiledMethod [
	
	| bytecodesPlusTrailerSize |
	bytecodesPlusTrailerSize := aCompiledMethod size
	                            - aCompiledMethod initialPC + 1.

	self
		nextPutByte: TypeCodeCompiledBlock;
		nextPutInteger: aCompiledMethod header;
		nextPutLengthEncodedInteger: bytecodesPlusTrailerSize.
	"literals
	Here we have to take care about outer code: just skip it for now (we store clean blocks)
	It is needed for debugging and printing, but not execution"

	1 to: aCompiledMethod numLiterals -1  do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	
	"variable part"
	self nextPutBytesFrom: aCompiledMethod bytecodes

]

{ #category : #writing }
SoilSerializer >> nextPutCompiledMethod: aCompiledMethod [

	| bytecodesPlusTrailerSize |
	bytecodesPlusTrailerSize := aCompiledMethod size
	                            - aCompiledMethod initialPC + 1.

	self
		nextPutByte: TypeCodeCompiledMethod;
		nextPutInteger: aCompiledMethod header;
		nextPutLengthEncodedInteger: bytecodesPlusTrailerSize.
	"we store all literals"
	"LiteralVariable (and subclasses) do not store the value, we will re-lookup by name (or create an Undeclared) on materialization.
	The classBinding (last literal) is a GlobalVariable, too"
	1 to: aCompiledMethod numLiterals do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	"variable part, we do *not* store the sourcePointer for now"
	self nextPutBytesFrom: aCompiledMethod bytecodes
	
]

{ #category : #writing }
SoilSerializer >> nextPutDictionary: aDictionary [ 
	self 
		nextPutByte: TypeCodeDictionary;
		nextPutLengthEncodedInteger: aDictionary size.
	aDictionary keysAndValuesDo: [:key :value |
		key soilSerialize: self.
		value soilSerialize: self ]
]

{ #category : #registry }
SoilSerializer >> nextPutProxy: aProxy [
	"A proxy is a reference that has not been read. Writing it as one is the whole point:
	resolving it first reads the cluster it points at, only to throw that object away
	again and write its id - one read per reference, every time an object is written back.

	If there is no registry, or it will not take the proxy, there is nothing to write a
	reference into and the object itself has to go in."
	| index |
	index := externalObjectRegistry
		ifNil: [ 0 ]
		ifNotNil: [ externalObjectRegistry indexOfExternalReference: aProxy ].
	index = 0 ifTrue: [ ^ aProxy soilRealObject soilSerialize: self ].
	self nextPutExternalReference: index
]

{ #category : #registry }
SoilSerializer >> nextPutExternalReference: anInteger [
	self 
		nextPutByte: TypeCodeExternalReference; 
		nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilSerializer >> nextPutIdentityDictionary: anIdentityDictionary [ 
	self 
		nextPutByte: TypeCodeIdentityDictionary;
		nextPutLengthEncodedInteger: anIdentityDictionary size.
	anIdentityDictionary keysAndValuesDo: [:key :value |
		key soilSerialize: self.
		value soilSerialize: self ]
]

{ #category : #writing }
SoilSerializer >> nextPutInternalReference: anInteger [ 
	self 
		nextPutByte: TypeCodeInternalReference; 
		nextPutLengthEncodedInteger: anInteger 
]

{ #category : #writing }
SoilSerializer >> nextPutObjectType [
	self nextPutByte: TypeCodeObject 
]

{ #category : #writing }
SoilSerializer >> nextPutOrderedCollection: aCollection [ 
	self
		nextPutByte: TypeCodeOrderedCollection;
		nextPutLengthEncodedInteger: aCollection size.
	aCollection do: [:each | each soilSerialize: self ].
]

{ #category : #writing }
SoilSerializer >> nextPutPersistentDictionary: aPersistentDictionary [ 
	self 
		nextPutByte: TypeCodePersistentDictionary;
		nextPutLengthEncodedInteger: aPersistentDictionary size.
	aPersistentDictionary keysAndValuesDo: [:key :value |
		key soilSerialize: self.
		value soilSerialize: self ]
]

{ #category : #writing }
SoilSerializer >> nextPutProcessorScheduler: aProcessorScheduler [ 
	self nextPutByte: TypeCodeProcessScheduler 
]

{ #category : #writing }
SoilSerializer >> nextPutSmalltalkImage: aCollection [ 
	self nextPutByte: TypeCodeSmalltalkImage
]

{ #category : #writing }
SoilSerializer >> nextPutSystemDictionary: aCollection [ 
	self nextPutByte: TypeCodeSystemDictionary 
]

{ #category : #writing }
SoilSerializer >> nextPutUUID: aUUID [
	| uuidData |
	uuidData := SystemVersion current major < 12 ifTrue: [ aUUID ] ifFalse: [ aUUID uuidData ].
	self 
		nextPutByte: TypeCodeUUID; 
		nextPutLengthEncodedInteger: uuidData size;
		nextPutBytesFrom: uuidData
]

{ #category : #writing }
SoilSerializer >> notSupportedError: anObject [ 
	Error signal: 'serialization of class ', anObject class name asString , ' is not supported'
]

{ #category : #registry }
SoilSerializer >> registerIndex: anIndex [ 
	externalObjectRegistry registerIndex: anIndex
]

{ #category : #registry }
SoilSerializer >> registerObject: anObject ifAbsent: aBlock [
	| index externalIndex |
	objectIdTable isEmpty ifTrue: [
		"the cluster root is serialized first so we put it in the object able
		for later references. Above we checked for an empty object table so
		later references to the cluster root will become an internal reference"
		objectIdTable add: anObject.
		^ aBlock value ].
	index := objectIdTable identityIndexOf: anObject.
	(index = 0 and: [ externalObjectRegistry notNil and: [
		externalObjectRegistry standsForTheClusterRoot: anObject ] ]) ifTrue: [
			"a migration replaced the cluster root while exporting, and something embedded
			in the cluster still points back at the object it replaced - that is this same
			root, and it is written as the reference it is instead of a second time"
			index := objectIdTable identityIndexOf: clusterRoot ].
	(index > 0) ifTrue: [
		self nextPutInternalReference: index.
		^ self ].
	externalIndex := externalObjectRegistry
		ifNotNil: [ externalObjectRegistry indexOfExternalReference: anObject ]
		ifNil: [
			"if there is no external object repository we cannot
			resolve external objects, hence we treat them as
			internal. This might be too dangerous later and might
			be removed"
			0 ].
	(anObject ~~ clusterRoot and: [ externalIndex > 0 ])
		ifTrue: [
			self nextPutExternalReference: externalIndex ]
		ifFalse: [
			objectIdTable add: anObject.
			soil ifNotNil: [  
				soil notificationHandler objectSerialized: anObject ].
			aBlock value ]
]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	| objectToSerialize |
	objectToSerialize := anObject soilSerializationReplacement.
	clusterRoot := objectToSerialize.
	clusterRoot soilSerialize: self.
	stream flush.
	^ stream contents
]

{ #category : #public }
SoilSerializer >> serializeBehaviorDescriptionFor: anObject [
	| index |
	index := externalObjectRegistry indexOfBehaviorDescription: anObject class.
	self nextPutObjectType.
	self nextPutLengthEncodedInteger: index.
	^ externalObjectRegistry behaviorDescriptionAt: index
]

{ #category : #public }
SoilSerializer >> serializeToBytes: anObject [ 

	^ (self stream: ByteArray new writeStream) 
		serialize: anObject

]

{ #category : #accessing }
SoilSerializer >> soil [

	^ soil
]

{ #category : #accessing }
SoilSerializer >> soil: anObject [

	soil := anObject
]

{ #category : #accessing }
SoilSerializer >> transaction [
	^ transaction 
]

{ #category : #accessing }
SoilSerializer >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
