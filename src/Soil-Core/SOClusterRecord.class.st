Class {
	#name : #SOClusterRecord,
	#superclass : #Object,
	#instVars : [
		'object',
		'transaction',
		'objectId',
		'references',
		'bytes',
		'committed'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SOClusterRecord class >> readFrom: aStream [
	^ self new 
		readFrom: aStream
]

{ #category : #'instance creation' }
SOClusterRecord >> addReference: reference [
	references detect: [ :each | each = reference ] ifFound: [ self halt ].
	references add: reference 
]

{ #category : #'as yet unclassified' }
SOClusterRecord >> assignObjectIds: aSOObjectRepository [ 
	references do: [ :reference |
		reference initializeId: aSOObjectRepository ]
]

{ #category : #accessing }
SOClusterRecord >> basicReferenceAt: anInteger [ 
	^ references at: anInteger
]

{ #category : #accessing }
SOClusterRecord >> bytes [
	^ bytes
]

{ #category : #accessing }
SOClusterRecord >> bytes: anObject [

	bytes := anObject
]

{ #category : #asserting }
SOClusterRecord >> committed [ 
	committed := true
]

{ #category : #initialization }
SOClusterRecord >> initialize [ 
	super initialize.
	references := OrderedCollection new.
	committed := false.

]

{ #category : #'as yet unclassified' }
SOClusterRecord >> materializeObject [
	object := self newMaterializer 
		stream: bytes readStream;
		externalObjectRegistry: self;
		materialize
]

{ #category : #'instance creation' }
SOClusterRecord >> newMaterializer [ 
	^ transaction newMaterializer
]

{ #category : #accessing }
SOClusterRecord >> object [
	^ object
]

{ #category : #accessing }
SOClusterRecord >> object: anObject [
	object := anObject
]

{ #category : #accessing }
SOClusterRecord >> objectId [
	^ objectId
]

{ #category : #accessing }
SOClusterRecord >> objectId: aSOObjectId [ 
	
	objectId := aSOObjectId 
]

{ #category : #printing }
SOClusterRecord >> printOn: aStream [ 
	aStream << 'record: '.
	objectId printOn: aStream.
	aStream << ' '.
	object printOn: aStream.
	
]

{ #category : #'instance creation' }
SOClusterRecord >> readFrom: stream [ 
	| numberOfReferences objectSize |
	numberOfReferences := (stream next: 2) asInteger.
	references := OrderedCollection new.
	1 to: numberOfReferences do: [:n | self addReference: (SOObjectId segment: 1 index: (stream next: 8) asInteger)]. 
	objectSize := (stream next: 8) asInteger.
	bytes := stream next: objectSize.
		
]

{ #category : #accessing }
SOClusterRecord >> referenceAt: anInteger [ 
	(references at: anInteger) ifNil: [ self halt ]. 
	^ SOObjectProxy new 
		objectId: (references at: anInteger);
		transaction: transaction;
		yourself 
]

{ #category : #accessing }
SOClusterRecord >> references [
	^ references
]

{ #category : #serializing }
SOClusterRecord >> serialize [
	^ ByteArray streamContents: [ :stream |
		self serializeOn: stream ]
				
]

{ #category : #serializing }
SOClusterRecord >> serializeObject [
	bytes := ByteArray streamContents: [ :s |
		transaction newSerializer 
			stream: s;
			externalObjectRegistry: self;
			serialize: object ].
	^ bytes
]

{ #category : #serializing }
SOClusterRecord >> serializeOn: stream [
	bytes ifNil: [ self serializeObject ].
	stream nextPutAll: ((references size) asByteArrayOfSize: 2).
	
	references do: [ :ref |
		stream nextPutAll: (ref index asByteArrayOfSize: 8) ].
	stream 
		nextPutAll: (bytes size asByteArrayOfSize: 8);
		nextPutAll: bytes .
]

{ #category : #accessing }
SOClusterRecord >> transaction [
	^ transaction
]

{ #category : #accessing }
SOClusterRecord >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
