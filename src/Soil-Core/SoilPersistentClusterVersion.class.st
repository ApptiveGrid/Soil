Class {
	#name : #SoilPersistentClusterVersion,
	#superclass : #SoilClusterRecord,
	#instVars : [
		'fingerprint',
		'length'
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

{ #category : #accessing }
SoilPersistentClusterVersion >> ensureFingerprint [
	fingerprint ifNil: [ 
		fingerprint := object soilRecursiveHash ]
]

{ #category : #testing }
SoilPersistentClusterVersion >> hasChanged [
	^ fingerprint ~= object soilRecursiveHash 
]

{ #category : #accessing }
SoilPersistentClusterVersion >> length [
	"how many bytes the record takes in the file, head and payload"
	^ length
]

{ #category : #accessing }
SoilPersistentClusterVersion >> location [
	^ SoilRecordLocation position: position length: length
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
	| objectSize |
	objectSize := self readHeadFrom: stream.
	bytes := stream next: objectSize.
	length := stream position - position
]

{ #category : #'instance creation' }
SoilPersistentClusterVersion >> readHeadFrom: stream [
	"everything before the payload; answers how many bytes of payload follow"
	| numberOfReferences numberOfBehaviorDescriptions numberOfIndexIds |
	position := stream position.
	version := stream nextLengthEncodedInteger.
	previousVersionPosition := stream nextLengthEncodedInteger.
	
	"behavior descriptions"
	numberOfBehaviorDescriptions := stream nextLengthEncodedInteger.
	behaviorDescriptions := OrderedCollection new: numberOfBehaviorDescriptions.
	1 to: numberOfBehaviorDescriptions do: [:n |
		behaviorDescriptions add: ((SoilVersionedObjectId segment: 0 index: stream nextLengthEncodedInteger)
			version: stream nextLengthEncodedInteger) ]. 
	"references"
	numberOfReferences := stream nextLengthEncodedInteger.
	references := OrderedCollection new: numberOfReferences.
	1 to: numberOfReferences do: [:n | 
		"reading without guard"
		self basicAddReference: (SoilObjectId readFrom: stream)]. 
	"indexes"
	numberOfIndexIds := stream nextLengthEncodedInteger.
	indexIds := OrderedCollection new: numberOfIndexIds.
	1 to: numberOfIndexIds do: [:n | | idSize |
		idSize := stream next.
		indexIds add: (stream next: idSize) asString ]. 
	"the size of the object in bytes that follow"
	^ stream nextLengthEncodedInteger
]

{ #category : #'instance creation' }
SoilPersistentClusterVersion >> readWithoutPayloadFrom: stream [
	"The record up to its payload, which is not read: enough to know its version, its
	previous version and how long it is"
	length := (self readHeadFrom: stream) + stream position - position
]

{ #category : #initialization }
SoilPersistentClusterVersion >> resetBytes [
	bytes := nil 
]

{ #category : #comparing }
SoilPersistentClusterVersion >> soilSizeInMemory [
	"recursive #sizeInMemory for Soil. 
	Note: only works for some objects, e.g. SoilPersistentClusterVersion"
	^ self sizeInMemory 
		+ objectId soilSizeInMemory 
		+ references soilSizeInMemory
		+ bytes sizeInMemory 
		"+ committed sizeInMemory" "boolean: shared"
		+ previousVersionPosition sizeInMemory 
		+ version sizeInMemory 
		+ behaviorDescriptions soilSizeInMemory
		+ indexIds soilSizeInMemory
		+ position sizeInMemory
		"+ changed sizeInMemory" "boolean: shared"
]
