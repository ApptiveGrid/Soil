Class {
	#name : #SOObjectRecord,
	#superclass : #Object,
	#instVars : [
		'changed',
		'object',
		'transaction',
		'objectId',
		'objects',
		'references',
		'bytes',
		'committed'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOObjectRecord class >> readFrom: aStream [
	^ self new 
		readFrom: aStream
]

{ #category : #adding }
SOObjectRecord >> addObject: anObject reference: anObjectId [
	objects addLast: anObject.
	references addLast: anObjectId
]

{ #category : #'instance creation' }
SOObjectRecord >> addReference: reference [
	references detect: [ :each | each = reference ] ifFound: [ self halt ].
	references add: reference 
]

{ #category : #'as yet unclassified' }
SOObjectRecord >> assignObjectIds: aSOObjectRepository [ 
	references do: [ :reference |
		reference initializeId: aSOObjectRepository ]
]

{ #category : #accessing }
SOObjectRecord >> basicReferenceAt: anInteger [ 
	^ references at: anInteger
]

{ #category : #'as yet unclassified' }
SOObjectRecord >> assignObjectIds: aSOObjectRepository [ 
	references do: [ :reference |
		reference initializeId: aSOObjectRepository ]
]

{ #category : #accessing }
SOObjectRecord >> bytes [
	^ bytes
]

{ #category : #accessing }
SOObjectRecord >> bytes: anObject [

	bytes := anObject
]

{ #category : #accessing }
SOObjectRecord >> changed: aBoolean [
	changed := aBoolean 
]

{ #category : #asserting }
SOObjectRecord >> committed [ 
	committed := true
]

{ #category : #testing }
SOObjectRecord >> hasChanged [
	^ changed 
]

{ #category : #accessing }
SOObjectRecord >> indexOf: anObject [
	| index |
	(anObject == object) ifTrue: [ ^ 0 ].
	index := objects indexOf: anObject.
	(index > 0) ifTrue: [ 
		"anObject is an external object but has already been registered. Just
		returning the index of the registered reference"
		^ index ].
	transaction objectIndex 
		at: anObject
		ifPresent: [ :record | 
			"anObject is an external object. Allocate a new local index and 
			return that"
			self addObject: record object reference: record objectId.
			^ references size ]
		ifAbsent: [ | record |
			(anObject class isSoilClusterRoot) ifTrue: [ 
				"anObject could be made cluster root per class side setting. In that 
				case we add it as cluster root to the transaction so the following
				will find it"
				transaction addClusterObject: anObject.
				record := transaction objectIndex at: anObject.
				self addObject: record object reference: record objectId. 
				^ references size ]. 
			].
	^ 0
]

{ #category : #initialization }
SOObjectRecord >> initialize [ 
	super initialize.
	changed := false.
	committed := false.
	references := OrderedCollection new.
	objects := OrderedCollection new.
]

{ #category : #'as yet unclassified' }
SOObjectRecord >> materializeObject [
	object := self newMaterializer 
		stream: bytes readStream;
		externalObjectRegistry: self;
		materialize
]

{ #category : #'instance creation' }
SOObjectRecord >> newMaterializer [ 
	^ transaction newMaterializer
]

{ #category : #accessing }
SOObjectRecord >> object [
	^ object
]

{ #category : #accessing }
SOObjectRecord >> object: anObject [
	object := anObject
]

{ #category : #accessing }
SOObjectRecord >> objectId [
	^ objectId
]

{ #category : #accessing }
SOObjectRecord >> objectId: aSOObjectId [ 
	
	objectId := aSOObjectId 
]

{ #category : #printing }
SOObjectRecord >> printOn: aStream [ 
	aStream << 'record: '.
	objectId printOn: aStream.
	aStream << ' '.
	object printOn: aStream.
	
]

{ #category : #'instance creation' }
SOObjectRecord >> readFrom: stream [ 
	| numberOfReferences objectSize |
	numberOfReferences := (stream next: 2) asInteger.
	references := OrderedCollection new.
	1 to: numberOfReferences do: [:n | self addReference: (SOObjectId segment: 1 index: (stream next: 8) asInteger)]. 
	objectSize := (stream next: 8) asInteger.
	bytes := stream next: objectSize.
		
]

{ #category : #accessing }
SOObjectRecord >> referenceAt: anInteger [ 
	(references at: anInteger) ifNil: [ self halt ]. 
	^ SOProxy new 
		objectId: (references at: anInteger);
		transaction: transaction;
		yourself 
]

{ #category : #accessing }
SOObjectRecord >> references [
	^ references
]

{ #category : #serializing }
SOObjectRecord >> serialize [
	^ ByteArray streamContents: [ :stream |
		self serializeOn: stream ]
				
]

{ #category : #serializing }
SOObjectRecord >> serializeObject [
	bytes := ByteArray streamContents: [ :s |
		transaction newSerializer 
			stream: s;
			externalObjectRegistry: self;
			serialize: object ].
	^ bytes
]

{ #category : #serializing }
SOObjectRecord >> serializeOn: stream [
	bytes ifNil: [ self serializeObject ].
	stream nextPutAll: ((references size) asByteArrayOfSize: 2).
	
	references do: [ :ref |
		stream nextPutAll: (ref index asByteArrayOfSize: 8) ].
	stream 
		nextPutAll: (bytes size asByteArrayOfSize: 8);
		nextPutAll: bytes .
]

{ #category : #asserting }
SOObjectRecord >> shouldBeCommitted [ 
	^ changed & committed not
]

{ #category : #accessing }
SOObjectRecord >> transaction [
	^ transaction
]

{ #category : #accessing }
SOObjectRecord >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
