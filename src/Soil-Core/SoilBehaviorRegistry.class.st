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

	self loadHistoryForBehaviorWithIndex: behaviorIndex transaction: transaction.

	versionsOfBehavior := versions at: behaviorIndex ifAbsent: [Error signal: 'shouldnt happen'].

	^versionsOfBehavior
		detect: [ :behav | behav version = version ]
		ifNone: [(SOObjectNotFound new segment: 0; index: behaviorIndex) signal]
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> behaviorVersionsUpTo: aSOBehaviorDescription transaction: transaction [
	| objectId chain offset |
	objectId := self 
		nameAt: aSOBehaviorDescription behaviorIdentifier 
		ifAbsent: [ Error signal: 'shouldnt happen' ].
	self loadHistoryForBehaviorWithIndex: objectId index transaction: transaction.
	chain := versions at: objectId index.
	chain first isCurrent ifFalse: [ 
		chain addFirst: ((SOBehaviorDescription for: aSOBehaviorDescription objectClass) version: (aSOBehaviorDescription version + 1))].
	offset := chain detectIndex: [ :each | each matchesDescription: aSOBehaviorDescription ].
	^ chain copyFrom: 1 to: offset
]

{ #category : #accessing }
SoilBehaviorRegistry >> flush [
	self index flush
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
	index := SoilSkipList new 
		path: self path;
		store: SoilPagedFileIndexStore new;
		initializeFilesystem;
		maxLevel: 8;
		keySize: 64;
		valueSize: 8.
	self addSpecialObjects.
	index writePages
]

{ #category : #'as yet unclassified' }
SoilBehaviorRegistry >> loadHistoryForBehaviorWithIndex: objectIndex transaction: transaction [
	|  records chain |

	"check if we loaded the history already"
	(versions includesKey: objectIndex ) ifTrue: [ ^ self ].

	records := transaction objectRepository metaSegment allVersionsAt: objectIndex.
	chain := records collect: [ :record |
		record
			transaction: transaction;
			materializeObject;
			object  ].

	versions
		at: objectIndex
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
		yourself
]

{ #category : #'instance creation' }
SoilBehaviorRegistry >> open [ 
	index ifNotNil: [ index close ].
	index :=  SoilSkipList new 
		store: SoilPagedFileIndexStore new;
		maxLevel: 16;
		keySize: 64;
		valueSize: 8;
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
