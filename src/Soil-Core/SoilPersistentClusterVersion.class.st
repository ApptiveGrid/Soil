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
SoilPersistentClusterVersion >> changed: aBoolean [
	changed := aBoolean 
]

{ #category : #'as yet unclassified' }
SoilPersistentClusterVersion >> detachFromSegment [
	"remove all information that belongs to the segment where the cluster
	was stored"
	version := 0.
	position := 0.
	previousVersionPosition := 0
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
	| numberOfReferences objectSize numberOfBehaviorDescriptions numberOfIndexIds |
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
	"object in bytes"
	objectSize := stream nextLengthEncodedInteger.
	bytes := stream next: objectSize.
		
]

{ #category : #initialization }
SoilPersistentClusterVersion >> resetBytes [
	bytes := nil 
]

{ #category : #asserting }
SoilPersistentClusterVersion >> shouldBeCommitted [ 
	^ changed and: [ committed not ]
]

{ #category : #comparing }
SoilPersistentClusterVersion >> soilSizeInMemory [
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
