Class {
	#name : #SoilSerializer,
	#superclass : #SoilBasicSerializer,
	#instVars : [
		'clusterRoot'
	],
	#category : #'Soil-Serializer'
}

{ #category : #'instance creation' }
SoilSerializer class >> on: aStream [ 
	^ self new 
		stream: aStream 
]

{ #category : #public }
SoilSerializer class >> serializeToBytes: anObject [ 

	^ (self on: ByteArray new writeStream) 
		serialize: anObject

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
SoilSerializer >> nextPutBehaviorDescription: description [
	self
		nextPutObjectType;
		nextPutLengthEncodedInteger: (description objectId index);
		nextPutLengthEncodedInteger: (description version)
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
	"literals"
	"for now we do store the class pointer in the last literal"
	1 to: aCompiledMethod numLiterals do: [ :i | 
		(aCompiledMethod literalAt: i) soilSerialize: self ].
	"variable part"
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
SoilSerializer >> nextPutMessage: aMessage [ 
	self nextPutByte: TypeCodeMessage.
	aMessage selector soilSerialize: self.
	aMessage arguments soilSerialize: self
]

{ #category : #writing }
SoilSerializer >> nextPutMessageSend: aMessageSend [ 
	self nextPutByte: TypeCodeMessageSend.
	aMessageSend receiver soilSerialize: self.
	aMessageSend selector soilSerialize: self.
	aMessageSend arguments soilSerialize: self
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
SoilSerializer >> nextPutSystemDictionary: aCollection [ 
	self nextPutByte: TypeCodeSystemDictionary 
]

{ #category : #writing }
SoilSerializer >> notSupportedError: anObject [ 
	Error signal: 'serialization of class ', anObject class name asString , ' is not supported'
]

{ #category : #registry }
SoilSerializer >> registerObject: anObject ifAbsent: aBlock [
	| index externalIndex |
	(anObject == clusterRoot) ifTrue: [
		"later references could reference the cluster root so we put
		it as first object to be able to have an internal reference to it"
		objects add: anObject.
		^ aBlock value ].
	index := objects identityIndexOf: anObject.
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
			objects add: anObject.
			aBlock value ]
]

{ #category : #private }
SoilSerializer >> serialize: anObject [
	clusterRoot := anObject.
	clusterRoot soilSerialize: self.
	stream flush.
	^ stream contents
]

{ #category : #public }
SoilSerializer >> serializeBehaviorDescriptionFor: anObject [
	| description |
	description := transaction behaviorDescriptionFor: anObject class.
	self nextPutBehaviorDescription: description.
	^ description
]

{ #category : #public }
SoilSerializer >> serializeToBytes: anObject [ 

	^ (self stream: ByteArray new writeStream) 
		serialize: anObject

]
