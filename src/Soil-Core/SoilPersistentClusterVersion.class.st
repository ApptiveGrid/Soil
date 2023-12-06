Class {
	#name : #SoilPersistentClusterVersion,
	#superclass : #SoilClusterRecord,
	#instVars : [
		'changed'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilPersistentClusterVersion >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitPersistentClusterVersion: self
]

{ #category : #converting }
SoilPersistentClusterVersion >> asNewClusterVersion [
	^ SoilNewClusterVersion new 
		object: object;
		objectId: objectId;
		transaction: transaction;
		previousVersionPosition: position;
		previousVersionRecord: self
]

{ #category : #api }
SoilPersistentClusterVersion >> beChanged [
	changed := true
]

{ #category : #accessing }
SoilPersistentClusterVersion >> behaviorDescriptionWithIndex: anInteger [ 
	(anInteger = 0) ifTrue: [ ^ SoilBehaviorDescription meta ].
	^ behaviorDescriptions at: anInteger 
]

{ #category : #accessing }
SoilPersistentClusterVersion >> changed: aBoolean [
	changed := aBoolean 
]

{ #category : #testing }
SoilPersistentClusterVersion >> hasChanged [
	^ changed 
]

{ #category : #initialization }
SoilPersistentClusterVersion >> initialize [ 
	super initialize.
	changed := false.

]

{ #category : #accessing }
SoilPersistentClusterVersion >> materializeObject [
	^ self materializeObjectUsing: self newMaterializer 
]

{ #category : #accessing }
SoilPersistentClusterVersion >> materializeObjectUsing: aMaterializer [
	object := aMaterializer 
		stream: bytes readStream;
		externalObjectRegistry: self;
		materialize.
	^ object
]

{ #category : #'instance creation' }
SoilPersistentClusterVersion >> newMaterializer [ 
	^ transaction newMaterializer
]

{ #category : #accessing }
SoilPersistentClusterVersion >> position [
	^ position 
]

{ #category : #printing }
SoilPersistentClusterVersion >> printOn: aStream [ 
	aStream << 'persistent record: '.
	objectId ifNotNil: [  
		aStream << 'oid='.
		objectId printOn: aStream ].
	object ifNotNil: [  
		aStream << ' '.
		object printOn: aStream ].
	aStream 
		<< 'version=' << version asString 
		<< ',previous=' << previousVersionPosition asString.
	

]

{ #category : #'instance creation' }
SoilPersistentClusterVersion >> readFrom: stream [ 
	| numberOfReferences objectSize materializer numberOfBehaviorDescriptions numberOfIndexIds |
	materializer := SoilBasicMaterializer new stream: stream.
	position := stream position.
	version := materializer nextLengthEncodedInteger.
	previousVersionPosition := materializer nextLengthEncodedInteger.
	
	"behavior descriptions"
	numberOfBehaviorDescriptions := materializer nextLengthEncodedInteger.
	behaviorDescriptions := OrderedCollection new: numberOfBehaviorDescriptions.
	1 to: numberOfBehaviorDescriptions do: [:n |
		behaviorDescriptions add: ((SoilVersionedObjectId segment: 0 index: materializer nextLengthEncodedInteger)
			version: materializer nextLengthEncodedInteger) ]. 
	"references"
	numberOfReferences := materializer nextLengthEncodedInteger.
	references := OrderedCollection new: numberOfReferences.
	1 to: numberOfReferences do: [:n | 
		"reading without guard"
		self basicAddReference: (SoilObjectId readFrom: stream)]. 
	"indexes"
	numberOfIndexIds := materializer nextLengthEncodedInteger.
	indexIds := OrderedCollection new: numberOfIndexIds.
	1 to: numberOfIndexIds do: [:n | | idSize |
		idSize := stream next.
		indexIds add: (stream next: idSize) asString ]. 
	"object in bytes"
	objectSize := materializer nextLengthEncodedInteger.
	bytes := stream next: objectSize.
		
]

{ #category : #serializing }
SoilPersistentClusterVersion >> serializeOn: stream [
	| serializer |
	bytes ifNil: [ self serializeObject ].
	self flag: #todo.
	serializer := SoilBasicSerializer new stream: stream.
	serializer 
		nextPutLengthEncodedInteger: version;
		nextPutLengthEncodedInteger: previousVersionPosition.
	"behavior description"
	serializer nextPutLengthEncodedInteger: behaviorDescriptions size.
	behaviorDescriptions do: [ :behavior |
		serializer 
			nextPutLengthEncodedInteger: behavior objectId index;
			nextPutLengthEncodedInteger: behavior version ].
	serializer
		nextPutLengthEncodedInteger: references size.
	"references"
	references do: [ :ref |
		"do not write zero index, try to allocate a new index before"
		(ref index = 0) ifTrue: [ 
			Error signal: 'there should be no uninitialized reference' ].
		ref writeOn: stream ].
	"indexes"
	serializer nextPutLengthEncodedInteger: indexIds size.
	indexIds do: [ :indexId |	
		stream 
			nextPut: indexId size;
			nextPutAll: indexId asByteArray].
	"objects in bytes"
	serializer nextPutLengthEncodedInteger: bytes size.
	stream nextPutAll: bytes .
]

{ #category : #asserting }
SoilPersistentClusterVersion >> shouldBeCommitted [ 
	^ changed and: [ committed not ]
]
