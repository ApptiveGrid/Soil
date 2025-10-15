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
		nameAt: #SoilBehaviorDescription
		put: SoilBehaviorDescription metaId
]

{ #category : #queries }
SoilBehaviorRegistry >> behaviorDescriptionWithIndex: behaviorIndex andVersion: version transaction: transaction [
	| versionsOfBehavior |

	self loadHistoryForBehaviorWithIndex: behaviorIndex transaction: transaction.

	versionsOfBehavior := versions at: behaviorIndex ifAbsent: [Error signal: 'shouldnt happen'].

	^versionsOfBehavior
		detect: [ :behav | behav version = version ]
		ifNone: [(SoilObjectNotFound new segment: 0; index: behaviorIndex) signal]
]

{ #category : #queries }
SoilBehaviorRegistry >> behaviorVersionsUpTo: aSOBehaviorDescription transaction: transaction [
	| objectId chain offset |
	objectId := self 
		nameAt: aSOBehaviorDescription behaviorIdentifier 
		ifAbsent: [ Error signal: 'shouldnt happen' ].
	self loadHistoryForBehaviorWithIndex: objectId index transaction: transaction.
	chain := versions at: objectId index.
	chain first isCurrent ifFalse: [ 
		chain addFirst: ((SoilBehaviorDescription for: aSOBehaviorDescription objectClass) version: (chain first version + 1))].
	offset := chain detectIndex: [ :each | each matchesDescription: aSOBehaviorDescription ].
	^ chain copyFrom: 1 to: offset
]

{ #category : #'open/close' }
SoilBehaviorRegistry >> close [
	index close
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
		            put: (OrderedCollection with: SoilBehaviorDescription meta); yourself
]

{ #category : #initialization }
SoilBehaviorRegistry >> initializeFilesystem [
	index := SoilSkipList new 
		beFileStore;
		path: self path;
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: 10;
		keySize: 64;
		valueSize: 8.
	self addSpecialObjects.
	index writePages
]

{ #category : #queries }
SoilBehaviorRegistry >> loadHistoryForBehaviorWithIndex: objectIndex transaction: transaction [
	|  records chain |

	"check if we loaded the history already"
	(versions includesKey: objectIndex ) ifTrue: [ ^ self ].

	records := self segment allVersionsAt: objectIndex.
	chain := records collect: [ :record |
		record
			transaction: transaction;
			materializeObject  ].

	versions
		at: objectIndex
		put: chain
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier ifAbsent: aBlock [
	^ self newIterator
		at: classIdentifier 
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier put: objectId [

	objectId index = 0 ifTrue: [
		Error signal: 'cannot add non-initialized object id' ].
	^ self newIterator at: classIdentifier add: objectId
]

{ #category : #accessing }
SoilBehaviorRegistry >> newIterator [
	^ self index newIterator 
		returnObjectId;
		yourself
]

{ #category : #'open/close' }
SoilBehaviorRegistry >> open [ 
	index ifNotNil: [ index close ].
	index :=  SoilSkipList new 
		beFileStore;
		path: self path;
		open
]

{ #category : #accessing }
SoilBehaviorRegistry >> path [
	^ soil objectRepository metaSegment indexManager path / #identifier , #index
]

{ #category : #initialization }
SoilBehaviorRegistry >> recreateIndex [ 
	| txn metaSegment record zeroFound |
	"this is a last resort action to recreate the index in a sane
	state. It assumes that all behavior descriptions are written 
	in the meta segement but the entry in the index is bogus. 
	So we read all from the segment and readd them"
	txn := soil newTransaction.
	[
		metaSegment := soil objectRepository metaSegment.
		3 to: metaSegment lastObjectIndex do: [ :n |
			record := txn materializeRecord: (metaSegment at: n). 
			self nameAt: record object behaviorIdentifier put: record objectId 
		].
		txn commit ] 
			ensure: [ txn abort ].
	"there are pages with multiple zero entries. The only way right now
	is to remove the same key until the ifAbsent block is executed"
	zeroFound := true.
	[ zeroFound ] whileTrue: [  
		index removeKey: 0 ifAbsent: [ zeroFound := false ] ].
	"as we are on it we can also compact the index"
	index compact
]

{ #category : #accessing }
SoilBehaviorRegistry >> segment [ 

	^ soil objectRepository metaSegment
]

{ #category : #accessing }
SoilBehaviorRegistry >> soil [

	^ soil
]

{ #category : #accessing }
SoilBehaviorRegistry >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #writing }
SoilBehaviorRegistry >> writeContentsToDisk [
	soil setup isFsyncEnabled ifTrue: [  
		self index writeContentsToDisk ]
]
