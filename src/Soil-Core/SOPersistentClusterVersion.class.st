Class {
	#name : #SOPersistentClusterVersion,
	#superclass : #SOClusterRecord,
	#instVars : [
		'changed',
		'position'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #converting }
SOPersistentClusterVersion >> asNewClusterVersion [
	^ SONewClusterVersion new
		object: object;
		objectId: objectId;
		transaction: transaction;
		previousVersionPosition: position;
		previousVersionRecord: self
]

{ #category : #'as yet unclassified' }
SOPersistentClusterVersion >> beChanged [
	changed := true
]

{ #category : #accessing }
SOPersistentClusterVersion >> changed: aBoolean [
	changed := aBoolean
]

{ #category : #testing }
SOPersistentClusterVersion >> hasChanged [
	^ changed
]

{ #category : #initialization }
SOPersistentClusterVersion >> initialize [
	super initialize.
	changed := false
]

{ #category : #'as yet unclassified' }
SOPersistentClusterVersion >> materializeObject [
	object := self newMaterializer
		stream: bytes readStream;
		externalObjectRegistry: self;
		materialize
]

{ #category : #'instance creation' }
SOPersistentClusterVersion >> newMaterializer [
	^ transaction newMaterializer
]

{ #category : #printing }
SOPersistentClusterVersion >> printOn: aStream [
	aStream << 'persistent record: '.
	objectId ifNotNil: [
		aStream << 'oid='.
		objectId printOn: aStream ].
	object ifNotNil: [
		aStream << ' '.
		object printOn: aStream ].
	aStream
		<< 'version=' << version asString
		<< ',previous=' << previousVersionPosition asString
]

{ #category : #'instance creation' }
SOPersistentClusterVersion >> readFrom: stream [
	| numberOfReferences objectSize materializer |
	materializer := SoilBasicMaterializer new stream: stream.
	position := stream position.
	version := materializer nextLengthEncodedInteger.
	previousVersionPosition := materializer nextLengthEncodedInteger.
	numberOfReferences := materializer nextLengthEncodedInteger.
	references := OrderedCollection new.
	1 to: numberOfReferences do: [:n | self addReference: (SOObjectId readFrom: stream)].
	objectSize := materializer nextLengthEncodedInteger.
	bytes := stream next: objectSize
]

{ #category : #asserting }
SOPersistentClusterVersion >> shouldBeCommitted [
	^ changed & committed not
]
