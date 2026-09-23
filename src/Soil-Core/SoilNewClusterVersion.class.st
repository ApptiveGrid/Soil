Class {
	#name : #SoilNewClusterVersion,
	#superclass : #SoilClusterRecord,
	#instVars : [
		'externalObjects',
		'previousVersionRecord'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SoilNewClusterVersion >> addIndexUpdate: anIndex [
	transaction addIndexUpdate: anIndex
]

{ #category : #adding }
SoilNewClusterVersion >> addObject: anObject reference: anObjectId [
	externalObjects add: anObject.
	self addReference: anObjectId
]

{ #category : #converting }
SoilNewClusterVersion >> asJournalEntry [
	| objectEntry entries |
	entries := OrderedCollection new.
	objectEntry := self hasPreviousVersion 
		ifTrue: [
			SoilNewObjectVersionEntry new
				oldBytes: previousVersionRecord serialize ]
		ifFalse: [ SoilNewObjectEntry new ].
	objectEntry 
		record: self;
		objectId: objectId;
		bytes: self serialize.
	entries add: objectEntry.

	^ entries
]

{ #category : #converting }
SoilNewClusterVersion >> asNewClusterVersion [
	^ self
]

{ #category : #converting }
SoilNewClusterVersion >> asPersistentClusterVersion [
	^ SoilPersistentClusterVersion new
		transaction: transaction;
		position: position;
		previousVersionPosition: previousVersionPosition;
		objectId: objectId;
		object: object;
		version: version;
		bytes: bytes
		
		 
]

{ #category : #api }
SoilNewClusterVersion >> detachFromSegment [
	"remove all information that belongs to the segment where the cluster
	was stored"
	super detachFromSegment.
	previousVersionRecord := nil 
]

{ #category : #testing }
SoilNewClusterVersion >> hasChanged [
	^ true
]

{ #category : #accessing }
SoilNewClusterVersion >> indexOfBehaviorDescription: aBehavior [
	| index |
	(aBehavior = SoilBehaviorDescription) ifTrue: [ ^ 0 ]. 
	index := behaviorDescriptions 
		detectIndex: [ :each | each behaviorIdentifier = aBehavior name ]
		ifNone: 0.
	(index > 0) ifTrue: [ ^ index ].
	behaviorDescriptions add: (transaction behaviorDescriptionFor: aBehavior).
	^ behaviorDescriptions size
]

{ #category : #accessing }
SoilNewClusterVersion >> indexOfExternalReference: anObject [
	(anObject == object) ifTrue: [ ^ 0 ].
	"a proxy says what it points at without being read, which is the one case where the id
	is known before the object is"
	anObject isSoilProxy ifTrue: [
		^ self referenceTo: anObject objectId for: anObject ].
	transaction objectIndex
		at: anObject
		ifPresent: [ :record |
			"anObject is an external object. Allocate a new local index and return that"
			^ self referenceTo: record objectId for: record object ]
		ifAbsent: [
			(anObject class isSoilClusterRoot) ifTrue: [
				"anObject could be made cluster root per class side setting. In that case we
				add it as cluster root to the transaction so the following will find it"
				transaction addClusterObject: anObject.
				^ self referenceTo: (transaction objectIndex at: anObject) objectId for: anObject ] ].
	^ 0
]

{ #category : #accessing }
SoilNewClusterVersion >> referenceTo: anObjectId for: anObject [
	"the index under which this cluster refers to anObjectId, adding it if this is the
	first time. The same target can arrive twice - once read, once as a proxy - and a
	cluster carries each reference once."
	| index |
	index := externalObjects identityIndexOf: anObject.
	index > 0 ifTrue: [ ^ index ].
	index := references indexOf: anObjectId.
	index > 0 ifTrue: [ ^ index ].
	self addObject: anObject reference: anObjectId.
	^ references size
]

{ #category : #initialization }
SoilNewClusterVersion >> initialize [
	super initialize.
	externalObjects := SoilObjectTable new
]

{ #category : #initialization }
SoilNewClusterVersion >> initializeObjectIdsIn: aSOTransaction [ 
	"assign indexes to all not yet initialized object records"
	objectId ifNotNil: [ objectId isInitialized ifFalse: [ aSOTransaction initializeObjectId: objectId ] ].
	(references, (behaviorDescriptions collect: #objectId)) 
		reject: #isInitialized 
		thenDo: [ :oid | aSOTransaction initializeObjectId: oid].
]

{ #category : #accessing }
SoilNewClusterVersion >> lockIndex [
	^ transaction lockObjectId: objectId
]

{ #category : #accessing }
SoilNewClusterVersion >> previousVersionRecord: anObject [

	previousVersionRecord := anObject
]

{ #category : #printing }
SoilNewClusterVersion >> printOn: aStream [ 
	aStream << 'new record: '.
	objectId printOn: aStream.
	aStream << ' previous postion: ' << previousVersionPosition asString.
	aStream << ' '.
	object printOn: aStream.
	
]

{ #category : #serializing }
SoilNewClusterVersion >> serializeObject [
	bytes := ByteArray streamContents: [ :s |
		transaction newSerializer 
			stream: s;
			externalObjectRegistry: self;
			serialize: object ].
	^ bytes
]

{ #category : #api }
SoilNewClusterVersion >> validateReadVersion [
	"a new object record cannot conflict as the record is not on disk"
	| currentPosition |
	(previousVersionPosition == 0) ifTrue: [ ^ self ].
	currentPosition := transaction objectRepository heapPositionOf: objectId.
	(previousVersionPosition = currentPosition) ifFalse: [ 
		SoilObjectHasConcurrentChange new
			objectId: objectId;
			signal ]
]
