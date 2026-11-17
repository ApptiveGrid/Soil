"
A SoilDerivedIndex indexes the objects of a SoilIndexedCollection under one key. The
key is derived from the indexed object by sending it #selector.

Like a SoilIndexedDictionary it keeps a SoilSkipList whose keys are the derived keys
and whose values are the object ids of the indexed objects. The key size is set per
derived index with #keySize:, the value size is always 8 (a SoilObjectId).

The index is connected on first use, see #index, like the index of a SoilIndexedDictionary.
Before the creating transaction commits it lives in memory only; the journal entry
written in #soilBasicSerialize: creates the file when the transaction commits.
"
Class {
	#name : #SoilDerivedIndex,
	#superclass : #Object,
	#instVars : [
		'selector',
		'id',
		'index',
		'segment',
		'transaction'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilDerivedIndex class >> selector: aSymbol [
	^ self new
		selector: aSymbol;
		createIndex;
		yourself
]

{ #category : #'instance creation' }
SoilDerivedIndex class >> selector: aSymbol keySize: anInteger [
	^ (self selector: aSymbol)
		keySize: anInteger;
		yourself
]

{ #category : #accessing }
SoilDerivedIndex class >> soilTransientInstVars [
	^ #( index segment transaction )
]

{ #category : #adding }
SoilDerivedIndex >> add: anObject objectId: objectId [
	| key oldValue |
	key := anObject perform: selector.
	oldValue := self newIterator at: key add: objectId.

	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: [ self segment ];
			 id: id;
			 key: (self index indexKey: key);
			 value: objectId;
			 oldValue: oldValue).
	^ objectId
]

{ #category : #initialization }
SoilDerivedIndex >> createIndex [
	"only a SoilSkipList is supported as backend"
	index := SoilSkipList new
		initializeHeaderPage;
		id: id;
		keySize: 16;
		valueSize: 8;
		maxLevel: 16;
		uniqueKeys: false;
		yourself
]

{ #category : #accessing }
SoilDerivedIndex >> id [
	^ id
]

{ #category : #accessing }
SoilDerivedIndex >> id: aString [
	"the id of the index this derived index uses. Only for one whose index is not
	connected yet - the importer gives an imported index the id of the index it
	created for it. Once connected, the index keeps the id it was connected under."
	index ifNotNil: [
		SoilUnsupportedError signal: 'the index of this derived index is connected already' ].
	id := aString
]

{ #category : #accessing }
SoilDerivedIndex >> index [
	"connected on first use, not when materialized, see SoilIndexedDictionary>>index.
	A copy-on-write version, so that all changes are per transaction"
	^ index ifNil: [
		index := ((transaction segmentAt: segment) indexAt: id) asCopyOnWrite.
		index id: id.
		index ]
]

{ #category : #initialization }
SoilDerivedIndex >> initialize [
	super initialize.
	id := SoilIndexedDictionary newIndexId
]

{ #category : #testing }
SoilDerivedIndex >> isPresentOnDisk [
	^ self index isPresentOnDisk
]

{ #category : #accessing }
SoilDerivedIndex >> keySize: anInteger [
	self index keySize: anInteger
]

{ #category : #'instance creation' }
SoilDerivedIndex >> newIterator [
	^ self index newIterator
		returnProxyForTransaction: transaction;
		journal: transaction soil journal;
		readVersion: transaction readVersion
]

{ #category : #printing }
SoilDerivedIndex >> printOn: aStream [
	super printOn: aStream.
	aStream << ' on #' << selector asString
]

{ #category : #journal }
SoilDerivedIndex >> segment [
	^ segment
]

{ #category : #journal }
SoilDerivedIndex >> segment: anObject [
	segment := anObject
]

{ #category : #accessing }
SoilDerivedIndex >> selector [
	^ selector
]

{ #category : #accessing }
SoilDerivedIndex >> selector: aStringOrSymbol [
	selector := aStringOrSymbol asSymbol
]

{ #category : #serializing }
SoilDerivedIndex >> soilBasicSerialize: aSerializer [
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndex: self.
	self isPresentOnDisk ifFalse: [
		transaction
			addJournalEntry: (self index newIndexEntry
				id: id;
				segment: (transaction objectIdOf: self) segment)
			head: true ]
]

{ #category : #serializing }
SoilDerivedIndex >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction
]

{ #category : #serializing }
SoilDerivedIndex >> soilLoadedIn: aTransaction [
	transaction := aTransaction
]

{ #category : #serializing }
SoilDerivedIndex >> soilMaterialized: aMaterializer [
	"remember where the index is - the segment of the cluster root this was read
	from. It is connected when it is first used, see #index"
	transaction := aMaterializer transaction.
	segment := aMaterializer segment
]

{ #category : #accessing }
SoilDerivedIndex >> values [
	^ self newIterator values
]
