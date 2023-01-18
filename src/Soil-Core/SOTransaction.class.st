Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'idMap',
		'objectMap',
		'recordsToCommit',
		'readVersion',
		'writeVersion',
		'behaviorDescriptions'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #aborting }
SOTransaction >> abort [
	recordsToCommit := nil.
	behaviorDescriptions := nil.
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
	| behaviorDescription objectId |
	"locally created behavior descriptions are always current and can
	be returned immediately"
	behaviorDescriptions
		at: aClass soilBehaviorIdentifier
		ifPresent: [ :description | ^ description ].
	"if we find the behaviorIdentifier in the registry and it is 
	current we can return it"
	objectId := soil behaviorRegistry
		nameAt: aClass soilBehaviorIdentifier
		ifAbsent: [ nil ].
		
	objectId ifNotNil: [ 
		behaviorDescription := (objectId index = 2)
			ifTrue: [ ^ SOBehaviorDescription meta ]
			ifFalse: [ (self objectWithId: objectId ifNone: [Error signal ]) objectId: objectId].
		"the description in the database might not be current, if not, we create a new one later"
		behaviorDescription isCurrent 
			ifTrue: [ ^ behaviorDescription ] ].
			
	"behaviorDescription is only set if we've found an old version"
	behaviorDescription 
		ifNotNil: [ 
			"modify existing description and increment version"
			behaviorDescription 
				initializeFromBehavior: aClass;
				incrementVersion.
			"add a new version record to keep the previous position"
			self makeNewVersion: behaviorDescription  ]
		ifNil: [  
			"this is a new description with version 1"
			behaviorDescription := (SOBehaviorDescription for: aClass)
				beFirstVersion;
				objectId: self newMetaObjectId.
			behaviorDescription objectId initializeIndex: self objectRepository.
			self atObjectId: behaviorDescription objectId putObject: behaviorDescription. ].
	
	behaviorDescriptions
		at: aClass soilBehaviorIdentifier
		put: behaviorDescription.
	^ behaviorDescription
]

{ #category : #'as yet unclassified' }
SOTransaction >> behaviorDescriptionWithIndex: index andVersion: version [
	| description |
	(index = 2) ifTrue: [ ^ SOBehaviorDescription meta ].
	description := self behaviorWithIndex: index ifNone: [ 
		(SOObjectNotFound segment: 0 index: index) signal ].
	(description version = version)
		ifTrue: [ ^ description ].
	^ self behaviorWithIndex: index andVersion: version ifNone: [ self halt ]
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

{ #category : #'as yet unclassified' }
SOTransaction >> behaviorWithIndex: objectId andVersion: version ifNone: aBlock [
	| list |
	idMap 
		detect: [ :each | each objectId = objectId ]
		ifFound: [ :record | 
			(record object version = version)
				ifTrue: [ ^ record object ] ].

	self flag: #todo.
	"this is slow because it fetches always all versions"
	list := self objectRepository allVersionsOf: (SOObjectId segment: 0 index: objectId).
	list do: [ :rec |
		rec
			transaction: self;
			materializeObject.
		(rec object version = version) ifTrue: [ ^ rec object ]  ].
	Error signal.
]

{ #category : #'as yet unclassified' }
SOTransaction >> behaviorWithIndex: objectId ifNone: aBlock [
	idMap 
		detect: [ :each | each objectId = objectId ]
		ifFound: [ :record | 
			^ record object ].

	^ (self objectRepository metaAt: objectId)
		transaction: self;
		materializeObject;
		object
]

{ #category : #accessing }
SOTransaction >> checkpoint [
	| bytes |
	writeVersion := self writeVersion.
	recordsToCommit := self recordsToCommit.
	self serializeObjects.
	recordsToCommit keysAndValuesDo: [ :objectId :record | 
		objectId initializeIndex: self objectRepository.
		record assignObjectIds: soil objectRepository.
		record version: writeVersion.
		bytes := record serialize.
		soil objectRepository 
			at: objectId 
			put: bytes.
		record committed  ].
	behaviorDescriptions do: [ :description |
		soil behaviorRegistry 
			nameAt: description value behaviorIdentifier 
			put: description objectId ].
	soil databaseVersion: writeVersion

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
	behaviorDescriptions := Dictionary new
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

{ #category : #public }
SOTransaction >> makeNewVersion: classDescription [
	| record |
	record := objectMap at: classDescription.
	recordsToCommit 
		at: record objectId 
		put: record asNewClusterVersion
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
SOTransaction >> newMetaObjectId [
	^ self objectRepository newMetaObjectId
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
SOTransaction >> readVersion: anInteger [ 
	readVersion := anInteger
]

{ #category : #accessing }
SOTransaction >> records [
	^ idMap values
]

{ #category : #accessing }
SOTransaction >> recordsToCommit [
	^ ((idMap select: [:each | each value shouldBeCommitted ])
		collect: [:each | each asNewClusterVersion version: writeVersion]) 
		as: OrderedIdentityDictionary 
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

{ #category : #accessing }
SOTransaction >> writeVersion [
	^ soil databaseVersion + 1 
]
