"
The SoilIndexedDictionary implements a Dictionary that uses an on-disk index.

A SoilIndexedDictionary has to be created with a backend, for now we have SoilBTree and SoilSkipList

	SoilIndexedDictionary newWithBackend: SoilSkipList

Keys are created with #asIndexKeyOfSize: with the keySize being configurable when creating the dictionary. 
Values are SoilObjectId instances (8 byte). 

The indexes store data on pages (currently 4kb) on disk.
"
Class {
	#name : #SoilIndexedDictionary,
	#superclass : #Object,
	#instVars : [
		'id',
		'transaction',
		'index',
		'segment',
		'dirty'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilIndexedDictionary class >> newIndexId [
	"the id a new index is created under, and the name of its file"
	^ UUID new asString36
]

{ #category : #'instance creation' }
SoilIndexedDictionary class >> newWithBackend: aClass [
	^ self new createIndexWith: aClass
]

{ #category : #accessing }
SoilIndexedDictionary class >> soilTransientInstVars [ 
	^ #( index segment dirty transaction )
]

{ #category : #accessing }
SoilIndexedDictionary >> at: key [ 
	^ self 
		at: key
		ifAbsent: [ KeyNotFound signalFor: key in: self ]

]

{ #category : #accessing }
SoilIndexedDictionary >> at: key ifAbsent: aBlock [
	^ self 
		basicAt: key 
		ifAbsent: aBlock
]

{ #category : #accessing }
SoilIndexedDictionary >> at: key ifAbsentPut: aBlock [

	^ self at: key ifAbsent: [ |value|
		value := aBlock value.
		self at: key put: value.
		value ]
]

{ #category : #accessing }
SoilIndexedDictionary >> at: key put: anObject [

	| objectId oldValue |
	objectId := transaction makeRoot: anObject.
	oldValue := self newIterator at: key add: objectId.

	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: [ self segment ];
			 id: id;
			 key: (index indexKey: key);
			 value: objectId;
			 oldValue: oldValue).

	self indexUpdated.
	^ objectId
]

{ #category : #accessing }
SoilIndexedDictionary >> atIndex: anInteger [
	^ self newIterator atIndex: anInteger
]

{ #category : #accessing }
SoilIndexedDictionary >> backend [
	"return the backend used, which is the class of the index that we use"
	^index class
]

{ #category : #accessing }
SoilIndexedDictionary >> basicAt: aString ifAbsent: aBlock [ 
	^ self newIterator at: aString ifAbsent: aBlock
]

{ #category : #rewriting }
SoilIndexedDictionary >> compact [ 
	index wrapped compact
]

{ #category : #initialization }
SoilIndexedDictionary >> createIndexWith: anIndexClass [
	index := anIndexClass new
		initializeHeaderPage;
		valueSize: 8;
		id: id;
		yourself
]

{ #category : #enumerating }
SoilIndexedDictionary >> do: aBlock [
 	self newIterator do: [ :objectId | 
 				aBlock value: objectId ]
]

{ #category : #accessing }
SoilIndexedDictionary >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilIndexedDictionary >> first: anInteger [

	^ self newIterator first: anInteger
]

{ #category : #accessing }
SoilIndexedDictionary >> id [
	^ id
]

{ #category : #accessing }
SoilIndexedDictionary >> index [
	^ index
]

{ #category : #accessing }
SoilIndexedDictionary >> indexUpdated [ 
	"This marker is idle and is kept anyway. Nothing reads #dirty but the guard below, and
	nothing reads the transaction's indexUpdatesToCommit at all: b249af9 gave that collection
	two readers in 2023, the cleanups around ce89216 took both away in June 2025, and d854cf9
	brought #addIndexUpdate: back from the v3 branch in January 2026 without them.

	Its old job is done elsewhere now. A transaction counts as changed through
	#hasJournalEntries, and the checkpoint reaches the indexes through
	SoilIndexManager>>#dirtyIndexes, which asks each SoilIndex for its own #dirtyPages -
	a different dirtiness than this one.

	That is why #removeKey:ifAbsent: does not call this and does not need to: a removal-only
	transaction commits and survives a reopen, which
	SoilIndexedDictionaryTest>>#testRemoveKeySurvivesReopen holds to."
	dirty ifFalse: [  
		dirty := true.
		transaction addIndexUpdate: self ].
]

{ #category : #initialization }
SoilIndexedDictionary >> initialize [ 
	super initialize.
	id := self class newIndexId.
	dirty := false
]

{ #category : #testing }
SoilIndexedDictionary >> isEmpty [
	^ self newIterator isEmpty
]

{ #category : #testing }
SoilIndexedDictionary >> isPresentOnDisk [
	^ index isPresentOnDisk 
]

{ #category : #accessing }
SoilIndexedDictionary >> keySize: anInteger [ 
	index keySize: anInteger 
]

{ #category : #accessing }
SoilIndexedDictionary >> last [
	^ self newIterator last
	
]

{ #category : #accessing }
SoilIndexedDictionary >> last: anInteger [
	^ self newIterator last: anInteger
]

{ #category : #accessing }
SoilIndexedDictionary >> maxLevel: anInteger [
	"Implemented here to allow to switch between SkipList and BTree easily in tests"
	index maxLevel: anInteger

]

{ #category : #accessing }
SoilIndexedDictionary >> moveKey: oldKey to: newKey [ 
	^ self 
		moveKey: oldKey 
		to: newKey 
		ifAbsent: [ KeyNotFound signalFor: oldKey in: self ]
]

{ #category : #accessing }
SoilIndexedDictionary >> moveKey: oldKey to: newKey ifAbsent: aBlock [
	"The transactional half of SoilIndexIterator>>#moveKey:to:ifAbsent:. Both index halves
	run on one iterator; what is added here are the two journal entries and marking the
	index for the commit. It does the two steps itself rather than calling the iterator's
	move, because the journal needs both values: the one that moved and the one that was
	overwritten at newKey.

	The value never leaves its SoilObjectId, so the object it refers to stays on disk. That
	is the reason this is one operation and not a #removeKey: followed by an #at:put:,
	which resolves the proxy through #makeRoot:. It matters for callers that move the same
	entry again and again, like a queue pushing out the due time of an entry under backoff.

	An entry already at newKey is overwritten, just like #at:put: does. The atomicity comes
	from the caller's transaction: an abort in between leaves the entry under its old key."
	| iterator objectId overwritten |
	iterator := self newIterator.
	objectId := (iterator removeKey: oldKey ifAbsent: [ ^ aBlock value ]) asSoilObjectId.
	overwritten := iterator at: newKey add: objectId.

	transaction addJournalEntry: (SoilRemoveKeyEntry new 
			 segment: [ self segment ];
			 id: id;
			 key: (index indexKey: oldKey);
			 oldValue: objectId).

	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: [ self segment ];
			 id: id;
			 key: (index indexKey: newKey);
			 value: objectId;
			 oldValue: overwritten).

	self indexUpdated.
	^ objectId
]

{ #category : #private }
SoilIndexedDictionary >> newIterator [
	^ index newIterator
		returnProxyForTransaction: transaction;
		journal: transaction soil journal;
		readVersion: transaction readVersion 

]

{ #category : #accessing }
SoilIndexedDictionary >> nextAfter: key [  
	^  self newIterator nextAfter: key
]

{ #category : #private }
SoilIndexedDictionary >> nextCloseTo: aKey [ 
	^ self newIterator nextCloseTo: aKey 
]

{ #category : #accessing }
SoilIndexedDictionary >> persistentIndex [
	^ index persistentIndex 
]

{ #category : #printing }
SoilIndexedDictionary >> printOn: aStream [ 
	super printOn: aStream.
	aStream << ' id=' << id asString
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key [
	^ self 
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key ifAbsent: aBlock [
	| oldValue |
	oldValue := self newIterator removeKey: key ifAbsent: [^ aBlock value].

	transaction addJournalEntry: (SoilRemoveKeyEntry new 
			segment: [ self segment ];
			id: id;
			key: (index indexKey: key); 
			oldValue: oldValue asSoilObjectId ) .

	^ oldValue
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key value: value [
	^ self 
		removeKey: key 
		value: value 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key value: value ifAbsent: aBlock [
	| oldValue |
	oldValue := self newIterator 
		removeKey: key 
		value: (transaction objectIdOf: value)  
		ifAbsent: [^ aBlock value].

	transaction addJournalEntry: (SoilRemoveKeyEntry new 
			segment: [ self segment ];
			id: id;
			key: (index indexKey: key); 
			oldValue: oldValue asSoilObjectId ) .

	^ oldValue
]

{ #category : #enumerating }
SoilIndexedDictionary >> reverseDo: aBlock [
 	self newIterator reverseDo: [ :objectId | 
 				aBlock value: objectId ]
]

{ #category : #rewriting }
SoilIndexedDictionary >> rewriteUsing: aBlock [
	index wrapped rewriteUsing: aBlock
]

{ #category : #accessing }
SoilIndexedDictionary >> second [
	^ self newIterator first; next
]

{ #category : #journal }
SoilIndexedDictionary >> segment [
	^ segment 
]

{ #category : #accessing }
SoilIndexedDictionary >> segment: anObject [

	segment := anObject
]

{ #category : #accessing }
SoilIndexedDictionary >> size [ 
	^ self newIterator size

]

{ #category : #serializing }
SoilIndexedDictionary >> soilBasicSerialize: aSerializer [
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndex: self.
	self isPresentOnDisk ifFalse: [ 
		transaction 
			addJournalEntry: (index newIndexEntry 
				id: id;
				segment: (transaction objectIdOf: self) segment)
			head: true ].


]

{ #category : #serializing }
SoilIndexedDictionary >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction
]

{ #category : #serializing }
SoilIndexedDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction.

]

{ #category : #serializing }
SoilIndexedDictionary >> soilMaterialized: aMaterializer [
	"connect the global index at materialization time when we
	know the cluster root which defines the location of the index.
	Store a copy-on-write version so all changes are per transaction"
	transaction := aMaterializer transaction.
	segment := aMaterializer segment.
	index := (aMaterializer indexAt: id) asCopyOnWrite.
	index id: id.
	dirty := false
]

{ #category : #accessing }
SoilIndexedDictionary >> transaction: aTransaction [ 
	transaction := aTransaction 
]

{ #category : #accessing }
SoilIndexedDictionary >> values [
	^ self newIterator values
]
