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
	dirty ifFalse: [  
		dirty := true.
		transaction addIndexUpdate: self ].
]

{ #category : #initialization }
SoilIndexedDictionary >> initialize [ 
	super initialize.
	id := UUID new asString36.
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
	"Move the entry at oldKey to newKey. The value travels as its SoilObjectId, so the
	referenced object is never materialized. Doing the same with #removeKey: followed by
	#at:put: does materialize it: #removeKey: answers an unresolved SoilObjectProxy, and
	#at:put: sends #makeRoot: which resolves it. That matters for callers who move a key
	repeatedly on the same entry, like a queue applying backoff to its due time.
	Both halves run in the caller's transaction, which is where the atomicity comes from.
	Moving needs a unique index, otherwise it is undefined which of the entries under oldKey
	travels. A dictionary is unique by definition, so there is nothing to check here; whoever
	lifts this to an index that allows duplicates has to answer that question first."
	| objectId oldValueAtNewKey |
	objectId := (self removeKey: oldKey ifAbsent: [ ^ aBlock value ]) asSoilObjectId.
	oldValueAtNewKey := self newIterator at: newKey add: objectId.

	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: [ self segment ];
			 id: id;
			 key: (index indexKey: newKey);
			 value: objectId;
			 oldValue: oldValueAtNewKey).

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
