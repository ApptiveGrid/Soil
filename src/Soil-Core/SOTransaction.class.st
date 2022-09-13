Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'objects',
		'newObjects',
		'objectIndex'
	],
	#category : #'Soil-Core'
}

{ #category : #adding }
SOTransaction >> addClusterObject: anObject [ 
	self 
		atObjectId: self newObjectId 
		putObject: anObject.
	^ anObject

]

{ #category : #accessing }
SOTransaction >> atObjectId: objectId putObject: anObject [
	| record |
	(objects at: anObject ifAbsent: [nil]) ifNotNil: [ Error signal: 'object should not be added already' ].
	(objectIndex at: objectId ifAbsent: [ nil ]) ifNotNil: [ Error signal: 'did not expect to be present' ].
	record := SOObjectRecord new
		changed: true; 
		object: anObject;
		objectId: objectId;
		transaction: self.
	objects at: objectId put: record.
	objectIndex at: anObject put: record
]

{ #category : #accessing }
SOTransaction >> commit [
	| lastId bytes recordBytes |
	lastId := 1.
	"iterate over all object ids to assign numbers before they get serialized"
	objects keys do: [ :id  |
		(id index = 0) ifTrue: [ lastId := lastId + 1. id index: lastId ] ].
	objects keysAndValuesDo: [ :id :record |
		record hasChanged ifTrue: [ 
			recordBytes := record serialize. 
			bytes := ByteArray streamContents: [ :s |
				self serializer 
					when: [ :obj | (obj = record object) not and: [ self isRoot: obj ] ] 
					substituteBy: [ :obj | SOProxy new id: (record indexOf: (objectIndex at: obj) objectId) ];
					object: record object;
					onStream: s;
					serialize ].
			recordBytes := ByteArray streamContents: [ :s |
					s nextPutAll: (((record references size * 8) + 2 + bytes size) asByteArrayOfSize: 8).
					s nextPutAll: ((record references size) asByteArrayOfSize: 2).
					record references do: [ :ref |
						s nextPutAll: (ref index asByteArrayOfSize: 8) ].
				s 
					"nextPutAll: (bytes size asByteArrayOfSize: 8);"
					nextPutAll: bytes ].
			self objectRepository 
				at: id 
				put: recordBytes ] ]
]

{ #category : #'as yet unclassified' }
SOTransaction >> idOf: anObject [ 
	| id |
	id := objectIndex at: anObject.
	(id index = 0) ifTrue: [ Error signal: 'index of object id is not initialized' ].
	^ id
]

{ #category : #initialization }
SOTransaction >> initialize [ 
	super initialize.
	objects := Dictionary new.
	objectIndex := Dictionary new.
]

{ #category : #testing }
SOTransaction >> isRoot: anObject [
	self flag: #todo.
	"this is surely not true but a shortcut for now"
	^ (objectIndex 
		at: anObject 
		ifAbsent: [ nil ]) notNil
]

{ #category : #'as yet unclassified' }
SOTransaction >> makeRoot: anObject [ 
	self addClusterObject: anObject
]

{ #category : #'as yet unclassified' }
SOTransaction >> materializationWithId: aSOObjectId ifNone: aBlock [
	| bytes s refSize refs record |
	bytes := self objectRepository at: aSOObjectId.
	s := bytes readStream.
	refSize := (s next: 2) asInteger.
	refs := OrderedCollection new.
	1 to: refSize do: [:n | refs add: (SOObjectId new index: (s next: 8) asInteger)]. 
	record := SOObjectRecord new 
		transaction: self;
		references: refs;
		objectId: aSOObjectId.
	SOCurrentRecord 
		value: record 
		during: [ record object: (FLMaterializer materializeFrom: s) ].
	^ record
	
]

{ #category : #'instance creation' }
SOTransaction >> newObjectId [ 
	^ SOObjectId new 
		index: 0
]

{ #category : #accessing }
SOTransaction >> objectIndex [
	^ objectIndex
]

{ #category : #'as yet unclassified' }
SOTransaction >> objectRepository [ 
	^ soil objectRepository
]

{ #category : #'as yet unclassified' }
SOTransaction >> objectWithId: anInteger ifNone: aBlock [
	| m |
	m := self materializationWithId: anInteger ifNone: aBlock.
	"m objects do: [ :each | each soilLoadedIn: self ]."
	^ m object
]

{ #category : #accessing }
SOTransaction >> root [
	| m |
	m := (self materializationWithId: (SOObjectId new segment: 1; index: 1) ifNone: [ nil ]).
	"m objects do: [ :each | each soilLoadedIn: self ].
	^ m root"
	^ m object
]

{ #category : #accessing }
SOTransaction >> root: anObject [

	| objectId |
	objectId := SOObjectId new
		            segment: 1;
		            index: 1.
	self atObjectId: objectId putObject: anObject
]

{ #category : #accessing }
SOTransaction >> serializer [
	| serializer |
	serializer := FLSerializer new.
	serializer
		"when: [ :obj | (obj = serializer object) not and: [ self isRoot: obj ] ] substituteBy: [ :obj | self idOf: obj. ]".
	^ serializer
]

{ #category : #accessing }
SOTransaction >> soil: aSoil [ 
	soil := aSoil
]
