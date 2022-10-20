Class {
	#name : #SOObjectRecord,
	#superclass : #Object,
	#instVars : [
		'changed',
		'object',
		'transaction',
		'objectId',
		'references',
		'bytes'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOObjectRecord class >> readFrom: aStream [
	^ self new 
		readFrom: aStream
]

{ #category : #accessing }
SOObjectRecord >> bytes [
	^ bytes
]

{ #category : #accessing }
SOObjectRecord >> changed: aBoolean [
	changed := aBoolean 
]

{ #category : #testing }
SOObjectRecord >> hasChanged [
	^ changed 
]

{ #category : #accessing }
SOObjectRecord >> indexOf: anObjectId [
	| index |
	index := references indexOf: anObjectId.
	^ index isZero 
		ifTrue: [ 
			references addLast: anObjectId.
			references size ]
		ifFalse: [ index ]
]

{ #category : #initialization }
SOObjectRecord >> initialize [ 
	super initialize.
	changed := false.
	references := OrderedCollection new
]

{ #category : #'as yet unclassified' }
SOObjectRecord >> materializeObject [
	object := SoilMaterializer new 
		stream: bytes readStream;
		materialize
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

{ #category : #'instance creation' }
SOObjectRecord >> readFrom: stream [ 
	| numberOfReferences objectSize |
	numberOfReferences := (stream next: 2) asInteger.
	references := OrderedCollection new.
	1 to: numberOfReferences do: [:n | references add: (SOObjectId segment: 1 index: (stream next: 8) asInteger)]. 
	objectSize := (stream next: 8) asInteger.
	bytes := stream next: objectSize.
		
]

{ #category : #accessing }
SOObjectRecord >> references [
	^ references
]

{ #category : #accessing }
SOObjectRecord >> references: aCollection [ 
	references := aCollection
]

{ #category : #serializing }
SOObjectRecord >> serialize [
	^ ByteArray streamContents: [ :stream |
		self serializeOn: stream ]
				
]

{ #category : #serializing }
SOObjectRecord >> serializeObject [
	^ ByteArray streamContents: [ :s |
		transaction serializer 
			stream: s;
			serialize: object ].
]

{ #category : #serializing }
SOObjectRecord >> serializeOn: stream [
	| objectBytes |
	objectBytes := self serializeObject.
	stream nextPutAll: ((references size) asByteArrayOfSize: 2).
	
	references do: [ :ref |
		stream nextPutAll: (ref index asByteArrayOfSize: 8) ].
	stream 
		nextPutAll: (objectBytes size asByteArrayOfSize: 8);
		nextPutAll: objectBytes .
]

{ #category : #accessing }
SOObjectRecord >> transaction [
	^ transaction
]

{ #category : #accessing }
SOObjectRecord >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
