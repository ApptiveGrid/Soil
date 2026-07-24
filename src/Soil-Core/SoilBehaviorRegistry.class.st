Class {
	#name : #SoilBehaviorRegistry,
	#superclass : #Object,
	#instVars : [
		'soil',
		'index',
		'versions',
		'versionsLock'
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
SoilBehaviorRegistry >> appendCommittedVersion: aBehaviorDescription forIndex: objectIndex [
	"Called right after a new behavior version has been successfully committed to disk
	(see SoilTransaction>>updateBehaviorHistoryCachesAfterCommit). If this behaviors
	history is already cached, extend it in place - O(1), no reload from disk needed,
	and the already-cached older versions remain valid forever since persisted behavior
	descriptions never change. If nothing is cached yet, there is nothing to do here:
	the next lookup will load the full, up-to-date history straight from disk."
	versionsLock critical: [
		(versions at: objectIndex ifAbsent: [ nil ]) ifNotNil: [ :chain |
			chain addFirst: aBehaviorDescription ] ]
]

{ #category : #queries }
SoilBehaviorRegistry >> behaviorDescriptionWithIndex: behaviorIndex andVersion: version transaction: transaction [
	| versionsOfBehavior found |
	found := versionsLock critical: [
		self ensureHistoryLoadedForBehaviorWithIndex: behaviorIndex transaction: transaction.
		versionsOfBehavior := versions 
			at: behaviorIndex 
			ifAbsent: [ Error signal: 'cannot find behavior description at index ', behaviorIndex asString ].
		versionsOfBehavior 
			detect: [ :behav | (behav version = version) and: [ 
				"class could have changed, clear current flag"
				behav clearCurrent. true ] ]
			ifNone: [ 
				"Should be rare now that new versions are appended to the cache right when
				they are committed - kept as a defensive fallback in case cache and disk
				ever disagree."
				versions removeKey: behaviorIndex.
				self ensureHistoryLoadedForBehaviorWithIndex: behaviorIndex transaction: transaction.
				versionsOfBehavior := versions 
					at: behaviorIndex 
					ifAbsent: [ Error signal: 'cannot find behavior description at index ', behaviorIndex asString ].
				versionsOfBehavior 
					detect: [ :behav | (behav version = version) and: [ behav clearCurrent. true ] ]
					ifNone: [ nil ] ] ].
	found ifNil: [ (SoilObjectNotFound new segment: 0; index: behaviorIndex) signal ].
	^ found
]

{ #category : #queries }
SoilBehaviorRegistry >> behaviorVersionsUpTo: aBehaviorDescription transaction: transaction [ 
	| objectId chain offset workingChain guess result |
	objectId := self 
		nameAt: aBehaviorDescription behaviorIdentifier 
		ifAbsent: [ Error signal: 'cannot find behavior description for ', aBehaviorDescription behaviorIdentifier ].
	result := versionsLock critical: [
		self ensureHistoryLoadedForBehaviorWithIndex: objectId index transaction: transaction.
		chain := versions at: objectId index.
		"If the persisted chain's head does not match the class's current live shape yet
		(no write has happened since the shape changed in the image), we need a stand-in
		for that purpose. It is purely local to this call and is never stored in the shared
		cache - only appendCommittedVersion:forIndex: (called after an actual commit)
		is allowed to add real entries to the cached chain."
		guess := chain first isCurrent
			ifTrue: [ nil ]
			ifFalse: [ (SoilBehaviorDescription for: aBehaviorDescription objectClass) version: chain first version + 1 ].
		workingChain := guess ifNil: [ chain ] ifNotNil: [ (OrderedCollection with: guess) , chain ].
		offset := workingChain detectIndex: [ :each | each matchesDescription: aBehaviorDescription ] ifNone: [ 0 ].
		offset = 0 ifTrue: [ 
			"Should be rare now that new versions are appended to the cache right when they
			are committed - kept as a defensive fallback in case cache and disk ever disagree."
			versions removeKey: objectId index.
			self ensureHistoryLoadedForBehaviorWithIndex: objectId index transaction: transaction.
			chain := versions at: objectId index.
			guess := chain first isCurrent
				ifTrue: [ nil ]
				ifFalse: [ (SoilBehaviorDescription for: aBehaviorDescription objectClass) version: chain first version + 1 ].
			workingChain := guess ifNil: [ chain ] ifNotNil: [ (OrderedCollection with: guess) , chain ].
			offset := workingChain detectIndex: [ :each | each matchesDescription: aBehaviorDescription ] ifNone: [
				(SoilObjectNotFound new segment: 0; index: objectId index) signal ] ].
		workingChain copyFrom: 1 to: offset ].
	^ result
]

{ #category : #'open/close' }
SoilBehaviorRegistry >> close [
	index close
]

{ #category : #private }
SoilBehaviorRegistry >> ensureHistoryLoadedForBehaviorWithIndex: objectIndex transaction: transaction [
	"Private. Caller must already hold versionsLock. Loads the full version history for
	this behavior from disk exactly once and caches it - persisted behavior descriptions
	are immutable, so once loaded a chain never needs to be reloaded, only extended
	(see SoilBehaviorRegistry>>appendCommittedVersion:forIndex:)."
	| records chain |
	(versions includesKey: objectIndex) ifTrue: [ ^ self ].
	records := self segment allVersionsAt: objectIndex.
	chain := records collect: [ :record |
		record
			transaction: transaction;
			materializeObject ].
	versions
		at: objectIndex
		put: chain
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
		            put: (OrderedCollection with: SoilBehaviorDescription meta); yourself.
	versionsLock := Semaphore forMutualExclusion
]

{ #category : #initialization }
SoilBehaviorRegistry >> initializeFilesystem [
	index := SoilSkipList new 
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
	versionsLock critical: [
		self ensureHistoryLoadedForBehaviorWithIndex: objectIndex transaction: transaction ]
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier ifAbsent: aBlock [
	^ self newIterator
		at: classIdentifier 
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier put: objectId [

	objectId index == 0 ifTrue: [
		Error signal: 'cannot add non-initialized object id' ].
	^ self newIterator at: classIdentifier add: objectId
]

{ #category : #accessing }
SoilBehaviorRegistry >> removeNameAt: classIdentifier ifAbsent: aBlock [
	"used to undo a nameAt:put: made during an import that failed partway through -
	see SoilGraphImporter>>import"
	^ self index removeKey: classIdentifier ifAbsent: aBlock
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
