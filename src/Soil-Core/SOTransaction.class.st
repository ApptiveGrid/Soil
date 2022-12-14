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

{ #category : #'as yet unclassified' }
SOTransaction >> allocateObjectId: aSOObjectId [ 
	aSOObjectId initializeIndex: self objectRepository 
]

{ #category : #accessing }
SOTransaction >> atObjectId: objectId putObject: anObject [
	| record |
	record := SONewClusterVersion new
		object: anObject;
		objectId: objectId;
		transaction: self.
	idMap at: objectId put: record.
	objectMap at: anObject put: record.
	recordsToCommit ifNotNil: [ recordsToCommit at: objectId put: record ]
]

{ #category : #public }
SOTransaction >> behaviorDescriptionFor: aClass [
	| classDescription objectId |
	classDescriptions
		at: aClass soilBehaviorIdentifier
		ifPresent: [ :description | ^ description ].
	soil behaviorRegistry
		nameAt: aClass soilBehaviorIdentifier
		ifPresent: [ :oid | | desc |
			desc := (oid index = 2)
				ifTrue: [SOBehaviorDescription meta objectId: oid ]
				ifFalse: [ | foundDesc |
					 "the description in the database might not be current, if not, we create a new one with the same ID"
					 foundDesc := (self objectWithId: oid ifNone: [Error signal ]) objectId: oid; yourself.
					 foundDesc isCurrent ifFalse: [ (SOBehaviorDescription for: aClass) objectId: oid ] ifTrue: [foundDesc]].
			^ desc ].

	classDescription := SOBehaviorDescription for: aClass.
	objectId := self newObjectId.
	classDescription objectId: objectId.
	self atObjectId: objectId putObject: classDescription.
	classDescriptions
		at: aClass soilBehaviorIdentifier
		put: classDescription.
	^ classDescription
]

{ #category : #'as yet unclassified' }
SOTransaction >> behaviorDescriptionWithId: aSOObjectId ifNone: aBlock [
	(aSOObjectId index = 2) ifTrue: [ ^ SOBehaviorDescription meta ].
	^ self objectWithId: aSOObjectId ifNone: aBlock
]

{ #category : #accessing }
SOTransaction >> behaviorRegistry [
	^ soil behaviorRegistry 
]

{ #category : #'as yet unclassified' }
SOTransaction >> behaviorVersionsUpTo: aSOBehaviorDescription [ 
	^ self behaviorRegistry 
		behaviorVersionsUpTo: aSOBehaviorDescription
		transaction: self .
	
]

{ #category : #accessing }
SOTransaction >> checkpoint [
	| bytes |
	recordsToCommit := ((idMap select: [:each | each value shouldBeCommitted ])
		collect: #asNewClusterVersion) as: OrderedIdentityDictionary .
	self serializeObjects.
	recordsToCommit keysAndValuesDo: [ :objectId :record | 
		objectId initializeIndex: self objectRepository.
		record assignObjectIds: soil objectRepository.
		bytes := record serialize.
		soil objectRepository 
			at: objectId 
			put: bytes.
		record committed  ].
	classDescriptions do: [ :description |
		soil behaviorRegistry 
			nameAt: description value behaviorIdentifier 
			put: description objectId ].

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

{ #category : #public }
SOTransaction >> markDirty: anObject [
	| record |
	record := objectMap 
		at: anObject 
		ifAbsent: [ Error signal: 'cannot mark dirty a non-existing root' ].
	record beChanged. 
	
]

{ #category : #'as yet unclassified' }
SOTransaction >> materializationWithId: objectId ifNone: aBlock [
	| record |
	record := (self objectRepository at: objectId)
		transaction: self;
		materializeObject.
	idMap at: objectId put: record.
	objectMap at: record object put: record.
	^ record object 

	
]

{ #category : #'instance creation' }
SOTransaction >> newClusterVersion [
	^ SONewClusterVersion new
		changed: true; 
		transaction: self.
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
SOTransaction >> newPersistentClusterVersion [
	^ SOPersistentClusterVersion new
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
