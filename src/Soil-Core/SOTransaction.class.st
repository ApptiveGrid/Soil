Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'idMap',
		'objectMap',
		'classDescriptions'
	],
	#category : #'Soil-Core'
}

{ #category : #aborting }
SOTransaction >> abort [
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
	(objectMap at: anObject ifAbsent: [nil]) ifNotNil: [ Error signal: 'object should not be added already' ].
	(idMap at: objectId ifAbsent: [ nil ]) ifNotNil: [ Error signal: 'did not expect to be present' ].
	record := SOObjectRecord new
		changed: true; 
		object: anObject;
		objectId: objectId;
		transaction: self.
	idMap at: objectId put: record.
	objectMap at: anObject put: record
]

{ #category : #accessing }
SOTransaction >> checkpoint [
	| bytes changed assoc objectId |
	"iterate over all object ids to assign numbers before they get serialized"
	"idMap keys do: [ :id  |
		(id index = 0) ifTrue: [ id setIndex: (self objectRepository segmentAt: id segment) allocateNextIndex ] ]."
	[ changed := (idMap associations select: [:each | each value shouldBeCommitted ]) asOrderedCollection. 
	  changed isEmpty ] whileFalse: [  
	idMap keys do: [ :id  |
		(id index = 0) ifTrue: [ id initializeId: self objectRepository ] ].
		assoc := changed removeFirst.
		"assoc key initializeId: self objectRepository."
		bytes := assoc value serialize. 
		self objectRepository 
			at: assoc key 
			put: bytes.
		assoc value committed ].
	classDescriptions do: [ :description |
		objectId := description objectId.
		objectId initializeId: self objectRepository.
		soil classRegistry 
			nameAt: description value classIdentifier 
			put: objectId ].
		
	
]

{ #category : #'as yet unclassified' }
SOTransaction >> class: classIdentifier version: versionIdentifier transaction: transaction [  
self halt.
	classDescriptions 
		at: classIdentifier 
		ifPresent: [ :description | ^ description ].
	soil classRegistry 
		nameAt: classIdentifier ifPresent: [ :id |
			^ self objectWithId: id ifNone: [ self halt ]  ].
	Error signal: 'cannot find class identifier ', classIdentifier asString.
]

{ #category : #public }
SOTransaction >> classDescriptionFor: aClass [
	| classDescription id |
	classDescriptions 
		at: aClass soilClassIdentifier 
		ifPresent: [ :description | ^ description ].
	soil classRegistry 
		nameAt: aClass soilClassIdentifier 
		ifPresent: [ :oid | | desc |
			desc := (oid index = 2) 
				ifTrue: [(SOClassDescription for: SOClassDescription) objectId: oid ]
				ifFalse: [ (self objectWithId: oid ifNone: [Error signal ]) objectId: oid; yourself ].
			^ desc ].
	(aClass = SOClassDescription) ifTrue: [  self halt ].
	classDescription := (SOClassDescription for: aClass).
	self addClusterObject: classDescription.
	id := (objectMap at: classDescription) objectId. 
	id initializeId: soil objectRepository.
	classDescription objectId: id.
	classDescriptions
		at: aClass soilClassIdentifier 
		put: classDescription.
	^ classDescription 
	
]

{ #category : #'as yet unclassified' }
SOTransaction >> classDescriptionWithId: aSOObjectId ifNone: aBlock [ 
	(aSOObjectId index = 2) ifTrue: [ ^ SOClassDescription for: SOClassDescription ].
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
	at: objectId 
	ifPresent: [ :record | ^ record object ].
	
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
SOTransaction >> soil: aSoil [ 
	soil := aSoil
]
