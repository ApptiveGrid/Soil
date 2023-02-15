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
SoilBehaviorRegistry >> behaviorDescriptionWithIndex: behaviorIndex andVersion: version transaction: transaction [
	| versionsOfBehavior |

	self loadHistoryForBehaviorWithId: (SOObjectId segment: 0 index: behaviorIndex) transaction: transaction.

	versionsOfBehavior := versions at: behaviorIndex ifAbsent: [self halt].

	^versionsOfBehavior
		detect: [ :behav | behav version >= version ]
		ifNone: [(SOObjectNotFound new segment: 0; index: behaviorIndex) signal]
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> behaviorVersionsUpTo: aSOBehaviorDescription transaction: transaction [
	| objectId chain offset |
	objectId := self 
		nameAt: aSOBehaviorDescription behaviorIdentifier 
		ifAbsent: [ self halt ].
	self loadHistoryForBehaviorWithId: objectId transaction: transaction.
	chain := versions at: objectId index.
	chain first isCurrent ifFalse: [ 
		chain addFirst: ((SOBehaviorDescription for: aSOBehaviorDescription objectClass) version: (aSOBehaviorDescription version + 1))].
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
		            at: 2
		            put: (OrderedCollection with: SOBehaviorDescription meta); yourself
]

{ #category : #initialization }
SoilBehaviorRegistry >> initializeFilesystem [
	self open.
	index initializeList.
	self addSpecialObjects
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> loadHistoryForBehaviorWithId: objectId transaction: transaction [
	|  records chain |

	"check if we loaded the history already"
	(versions includesKey: objectId index ) ifTrue: [ ^ self ].

	records := transaction objectRepository allVersionsOf: objectId.
	chain := records collect: [ :record |
		record
			transaction: transaction;
			materializeObject;
			object  ].

	versions
		at: objectId index
		put: chain
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
