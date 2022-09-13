Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'objects',
		'objectIndex'
	],
	#category : #'Soil-Core'
}

{ #category : #aborting }
SOTransaction >> abort [
	soil := nil.
	objects := nil.
	objectIndex := nil
]

{ #category : #adding }
SOTransaction >> addClusterObject: anObject [ 
	objectIndex at: anObject ifPresent: [ ^ self ].
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
	| bytes |
	"iterate over all object ids to assign numbers before they get serialized"
	objects keys do: [ :id  |
		(id index = 0) ifTrue: [ id index: (self objectRepository segmentWithId: id segment) allocateNextIndex ] ].
	objects keysAndValuesDo: [ :id :record |
		record hasChanged ifTrue: [ 
			bytes := record serialize. 
			self objectRepository 
				at: id 
				put: bytes ] ]
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
SOTransaction >> isAborted [
	^ soil isNil & objects isNil & objectIndex isNil
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
	| bytes record |
	^ (self objectRepository at: aSOObjectId)
		transaction: self;
		objectId: aSOObjectId;
		materializeObject.
	
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
SOTransaction >> objectWithId: objectId ifNone: aBlock [
	| record |
	objects at: objectId ifPresent: [ :rec | ^ rec object ].
	
	record := self materializationWithId: objectId ifNone: aBlock.
	objects at: objectId put: record.
	objectIndex at: record object put: record.
	^ record object
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
