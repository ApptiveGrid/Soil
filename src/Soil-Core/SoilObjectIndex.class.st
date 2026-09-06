"
A SoilObjectIndex indexes objects of a SoilIndexedCollection under one key. The
key is derived from the indexed object by sending it #selector.

Like a SoilIndexedDictionary it keeps a backend index (SoilSkipList or SoilBTree)
whose keys are the derived keys and whose values are the object ids of the indexed
objects. Before the creating transaction commits, that backend index lives in
memory (see SoilMemoryIndexStore); the journal entry written in #soilBasicSerialize:
creates the file when the transaction commits, and #soilMaterialized: reconnects
to the index in the segment afterwards.
"
Class {
	#name : #SoilObjectIndex,
	#superclass : #Object,
	#instVars : [
		'selector',
		'index',
		'id',
		'segment',
		'transaction'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilObjectIndex class >> soilTransientInstVars [
	^ #( index segment transaction )
]

{ #category : #adding }
SoilObjectIndex >> add: anObject objectId: objectId [
	| key oldValue |
	key := anObject perform: selector.
	oldValue := self newIterator at: key add: objectId.

	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: [ self segment ];
			 id: id;
			 key: (index indexKey: key);
			 value: objectId;
			 oldValue: oldValue).
	^ objectId
]

{ #category : #accessing }
SoilObjectIndex >> id [
	^ id
]

{ #category : #accessing }
SoilObjectIndex >> index [
	^ index
]

{ #category : #accessing }
SoilObjectIndex >> index: anIndex [
	index := anIndex
]

{ #category : #initialization }
SoilObjectIndex >> indexClass: aClass [
	index := aClass new
		beMemoryStore;
		initializeHeaderPage;
		id: id;
		keySize: 16;
		valueSize: 8;
		maxLevel: 16;
		uniqueKeys: false;
		yourself
]

{ #category : #initialization }
SoilObjectIndex >> initialize [
	super initialize.
	id :=  UUID new asString36
]

{ #category : #testing }
SoilObjectIndex >> isPresentOnDisk [
	^ index isPresentOnDisk
]

{ #category : #'instance creation' }
SoilObjectIndex >> newIterator [
	^ index newIterator
		returnProxyForTransaction: transaction;
		journal: transaction soil journal;
		readVersion: transaction readVersion
]

{ #category : #printing }
SoilObjectIndex >> printOn: aStream [
	super printOn: aStream.
	aStream << ' on #' << selector asString
]

{ #category : #journal }
SoilObjectIndex >> segment [
	^ segment
]

{ #category : #journal }
SoilObjectIndex >> segment: anObject [
	segment := anObject
]

{ #category : #accessing }
SoilObjectIndex >> selector [
	^ selector
]

{ #category : #accessing }
SoilObjectIndex >> selector: aStringOrSymbol [
	selector := aStringOrSymbol asSymbol
]

{ #category : #serializing }
SoilObjectIndex >> soilBasicSerialize: aSerializer [
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndex: self.
	self isPresentOnDisk ifFalse: [
		transaction
			addJournalEntry: (index newIndexEntry
				id: id;
				segment: (transaction objectIdOf: self) segment)
			head: true ]
]

{ #category : #serializing }
SoilObjectIndex >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction
]

{ #category : #serializing }
SoilObjectIndex >> soilLoadedIn: aTransaction [
	transaction := aTransaction
]

{ #category : #serializing }
SoilObjectIndex >> soilMaterialized: aMaterializer [
	"connect the index at materialization time when we know the cluster root
	which defines the location of the index. Store a copy-on-write version so
	all changes are per transaction"
	transaction := aMaterializer transaction.
	segment := aMaterializer segment.
	index := (aMaterializer indexAt: id) asCopyOnWrite.
	index id: id
]

{ #category : #accessing }
SoilObjectIndex >> values [
	^ self newIterator values
]
