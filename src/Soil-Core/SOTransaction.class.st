Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'idMap',
		'objectMap',
		'classDescriptions',
		'recordsToCommit'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #aborting }
SOTransaction >> abort [
	recordsToCommit := nil.
	classDescriptions := nil.
	soil := nil.
	idMap := nil.
	objectMap := nil
]

{ #category : #adding }
SOTransaction >> addClusterObject: anObject [ 
	objectMap at: anObject ifPresent: [ ^ self ].
	self 
		atObjectId: self newObjectId 
		putObject: anObject.
	^ anObject

]

{ #category : #accessing }
SOTransaction >> atObjectId: objectId putObject: anObject [
	| record |
	record := SOObjectRecord new
		changed: true; 
		object: anObject;
		objectId: objectId;
		transaction: self.
	idMap at: objectId put: record.
	objectMap at: anObject put: record.
	recordsToCommit ifNotNil: [ recordsToCommit at: objectId put: record ]
]

{ #category : #accessing }
SOTransaction >> checkpoint [
	| bytes |
	recordsToCommit := (idMap select: [:each | each value shouldBeCommitted ]) as: OrderedIdentityDictionary .
	self serializeObjects.
	recordsToCommit keysAndValuesDo: [ :objectId :record | 
		objectId initializeId: self objectRepository.
		record assignObjectIds: soil objectRepository.
		bytes := record serialize.
		soil objectRepository 
			at: objectId 
			put: bytes.
		record committed  ].
	classDescriptions do: [ :description | | objectId |
		objectId := description objectId.
		objectId initializeId: self objectRepository.
		soil behaviorRegistry 
			nameAt: description value behaviorIdentifier 
			put: objectId ].

]

{ #category : #public }
SOTransaction >> classDescriptionFor: aClass [
	| classDescription id |
	classDescriptions 
		at: aClass soilBehaviorIdentifier 
		ifPresent: [ :description | ^ description ].
	soil behaviorRegistry 
		nameAt: aClass soilBehaviorIdentifier 
		ifPresent: [ :oid | | desc |
			desc := (oid index = 2) 
				ifTrue: [(SOBehaviorDescription for: SOBehaviorDescription) objectId: oid ]
				ifFalse: [ (self objectWithId: oid ifNone: [Error signal ]) objectId: oid; yourself ].
			^ desc ].
	(aClass = SOBehaviorDescription) ifTrue: [  self halt ].
	classDescription := (SOBehaviorDescription for: aClass).
	id := self newObjectId.
	id initializeId: soil objectRepository.
	classDescription objectId: id.
	self atObjectId: id putObject: classDescription.
	classDescriptions
		at: aClass soilBehaviorIdentifier 
		put: classDescription.
	^ classDescription 
	
]

{ #category : #'as yet unclassified' }
SOTransaction >> classDescriptionWithId: aSOObjectId ifNone: aBlock [ 
	(aSOObjectId index = 2) ifTrue: [ ^ SOBehaviorDescription for: SOBehaviorDescription ].
	^ self objectWithId: aSOObjectId ifNone: aBlock
]

{ #category : #accessing }
SOTransaction >> commit [
	self 
		checkpoint;
		abort
]

{ #category : #aborting }
SOTransaction >> dirtyObjects [
	^ (idMap select: [ :each | each hasChanged ]) collect: #object
]

{ #category : #'as yet unclassified' }
SOTransaction >> idOf: anObject [ 
	| id |
	id := objectMap at: anObject.
	(id index = 0) ifTrue: [ Error signal: 'index of object id is not initialized' ].
	^ id
]

{ #category : #initialization }
SOTransaction >> initialize [ 
	super initialize.
	idMap := IdentityDictionary new.
	objectMap := IdentityDictionary new.
	classDescriptions := Dictionary new
]

{ #category : #testing }
SOTransaction >> isAborted [
	^ soil isNil & idMap isNil & objectMap isNil
]

{ #category : #testing }
SOTransaction >> isRoot: anObject [
	self flag: #todo.
	"this is surely not true but a shortcut for now"
	^ (objectMap 
		at: anObject 
		ifAbsent: [ nil ]) notNil
]

{ #category : #'as yet unclassified' }
SOTransaction >> makeRoot: anObject [ 
	self addClusterObject: anObject
]

{ #category : #'as yet unclassified' }
SOTransaction >> materializationWithId: objectId ifNone: aBlock [
	| record |
	record := (self objectRepository at: objectId)
		transaction: self;
		objectId: objectId;
		materializeObject.
	idMap at: objectId put: record.
	objectMap at: record object put: record.
	^ record object 

	
]

{ #category : #'instance creation' }
SOTransaction >> newMaterializer [
	^ soil newMaterializer 
		transaction: self;
		yourself
]

{ #category : #'instance creation' }
SOTransaction >> newObjectId [ 
	^ self objectRepository newObjectId
]

{ #category : #'instance creation' }
SOTransaction >> newObjectRecord [
	^ SOObjectRecord new
		changed: true; 
		transaction: self.
]

{ #category : #accessing }
SOTransaction >> newSerializer [
	soil ifNil: [ self halt ].
	^ soil newSerializer
		transaction: self;
		yourself

]

{ #category : #accessing }
SOTransaction >> objectIndex [
	^ objectMap
]

{ #category : #'as yet unclassified' }
SOTransaction >> objectRepository [ 
	^ soil objectRepository
]

{ #category : #'as yet unclassified' }
SOTransaction >> objectWithId: objectId ifNone: aBlock [
	idMap 
		detect: [ :each | each objectId = objectId ]
		ifFound: [ :record | ^ record object ].

	^ self materializationWithId: objectId ifNone: aBlock.
]

{ #category : #accessing }
SOTransaction >> records [
	^ idMap values
]

{ #category : #accessing }
SOTransaction >> root [
	idMap associations
		detect: [ :assoc | (assoc key segment = 1) & (assoc key index = 1) ]
		ifFound: [ :assoc | ^ assoc value object ].
	
	^ self 
		materializationWithId: self rootObjectId  
		ifNone: [ nil ].
]

{ #category : #accessing }
SOTransaction >> root: anObject [

	self 
		atObjectId: self rootObjectId  
		putObject: anObject
]

{ #category : #accessing }
SOTransaction >> rootObjectId [
	^ SOObjectId segment: 1 index: 1
]

{ #category : #accessing }
SOTransaction >> serializeObjects [
	| index key |
	index := 1.
	[ index <= recordsToCommit size ] whileTrue: [ 
		key := recordsToCommit keyAtIndex: index.
		(recordsToCommit at: key) serializeObject.
		index := index + 1 ]
]

{ #category : #accessing }
SOTransaction >> soil: aSoil [ 
	soil := aSoil
]
