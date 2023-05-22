Class {
	#name : #SoilPersistentClusterVersion,
	#superclass : #SoilClusterRecord,
	#instVars : [
		'changed',
		'position'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #converting }
SoilPersistentClusterVersion >> asNewClusterVersion [
	^ SoilNewClusterVersion new 
		object: object;
		objectId: objectId;
		transaction: transaction;
		previousVersionPosition: position;
		previousVersionRecord: self
]

{ #category : #'as yet unclassified' }
SoilPersistentClusterVersion >> beChanged [
	changed := true
]

{ #category : #'as yet unclassified' }
SoilPersistentClusterVersion >> behaviorDescriptionWithIndex: anInteger [ 
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

{ #category : #'as yet unclassified' }
SoilPersistentClusterVersion >> materializeObject [
	object := self newMaterializer 
		stream: bytes readStream;
		externalObjectRegistry: self;
		materialize
]

{ #category : #'instance creation' }
SoilPersistentClusterVersion >> newMaterializer [ 
	^ transaction newMaterializer
]

{ #category : #accessing }
SoilPersistentClusterVersion >> position [
	^ position 
]

{ #category : #accessing }
SoilPersistentClusterVersion >> position: anInteger [ 
	position := anInteger
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
	| numberOfReferences objectSize materializer numberOfBehaviorDescriptions |
	materializer := SoilBasicMaterializer new stream: stream.
	position := stream position.
	version := materializer nextLengthEncodedInteger.
	previousVersionPosition := materializer nextLengthEncodedInteger.
	
	numberOfBehaviorDescriptions := materializer nextLengthEncodedInteger.
	behaviorDescriptions := OrderedCollection new: numberOfBehaviorDescriptions.
	1 to: numberOfBehaviorDescriptions do: [:n |
		behaviorDescriptions add: ((SoilVersionedObjectId segment: 0 index: materializer nextLengthEncodedInteger)
			version: materializer nextLengthEncodedInteger) ]. 
	numberOfReferences := materializer nextLengthEncodedInteger.
	references := OrderedCollection new: numberOfReferences.
	1 to: numberOfReferences do: [:n | self addReference: (SoilObjectId readFrom: stream)]. 
	objectSize := materializer nextLengthEncodedInteger.
	bytes := stream next: objectSize.
		
]

{ #category : #asserting }
SoilPersistentClusterVersion >> shouldBeCommitted [ 
	^ changed & committed not
]
