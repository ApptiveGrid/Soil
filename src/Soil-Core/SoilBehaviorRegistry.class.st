Class {
	#name : #SoilBehaviorRegistry,
	#superclass : #Object,
	#instVars : [
		'soil',
		'index',
		'versions'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SoilBehaviorRegistry >> addSpecialObjects [
	self
		nameAt: #SOBehaviorDescription
		put: SOBehaviorDescription metaId
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> behaviorVersionsUpTo: aSOBehaviorDescription transaction: transaction [
	| objectId records chain offset |
	objectId := self
		nameAt: aSOBehaviorDescription behaviorIdentifier
		ifAbsent: [ self halt ].
	records := soil objectRepository
		allVersionsOf: objectId.
	chain := records collect: [ :record |
		record
			transaction: transaction;
			materializeObject;
			object  ].
	chain first isCurrent ifFalse: [
		chain addFirst: (SOBehaviorDescription for: aSOBehaviorDescription objectClass) ].
	versions
		at: aSOBehaviorDescription behaviorIdentifier
		put: chain.
	offset := chain detectIndex: [ :each | each matchesDescription: aSOBehaviorDescription ].
	^ chain copyFrom: 1 to: offset
]

{ #category : #accessing }
SoilBehaviorRegistry >> index [
	^ index
]

{ #category : #initialization }
SoilBehaviorRegistry >> initialize [
	super initialize.
	versions := Dictionary new
]

{ #category : #initialization }
SoilBehaviorRegistry >> initializeFilesystem [
	self open.
	index initializeList.
	self addSpecialObjects
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier ifAbsent: aBlock [
	^ (self index
		at: classIdentifier
		ifAbsent: aBlock)
			ifNotNil: [ :bytes | SOObjectId readFrom: bytes readStream ]
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier put: objectId [
	| dict |
	(objectId index = 0) ifTrue: [ Error signal: 'cannot add non-initialized object id' ].
	dict := self index
		at: classIdentifier put: objectId asByteArray;
		yourself.
	index writePages
]

{ #category : #'instance creation' }
SoilBehaviorRegistry >> open [
	index ifNotNil: [ index close ].
	index :=  SOPersistentSkipList new
		maxLevel: 16;
		keySize: 64;
		path: self path;
		open
]

{ #category : #accessing }
SoilBehaviorRegistry >> path [
	^ soil path / #'behaviors'
]

{ #category : #accessing }
SoilBehaviorRegistry >> soil: aSoil [
	soil := aSoil
]
