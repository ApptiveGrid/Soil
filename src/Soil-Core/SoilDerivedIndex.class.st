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
		'layout',
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

{ #category : #'instance creation' }
SoilDerivedIndex class >> uniqueSelector: aSymbol keySize: anInteger [
	"an index in which every object has its own value, the attribute takes the whole key size"
	^ (self selector: aSymbol)
		beUnique;
		keySize: anInteger;
		yourself
]

{ #category : #accessing }
SoilDerivedIndex class >> soilTransientInstVars [
	^ #( index segment transaction )
]

{ #category : #adding }
SoilDerivedIndex >> addKey: aKey objectId: objectId [
	"aKey is the key built with #keyFor:primaryKey:, it does not depend on the object id, so the
	entry of a new object is found in this transaction already"
	| oldValue |
	oldValue := self newIterator at: aKey add: objectId.

	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: [ self segment ];
			 id: id;
			 key: (self index indexKey: aKey);
			 value: objectId;
			 oldValue: oldValue).
	^ objectId
]

{ #category : #testing }
SoilDerivedIndex >> assertFreeKey: aKey of: anObject [
	"only for a unique index: the value of anObject must not be held by another element"
	(self includesKey: aKey) ifTrue: [
		SoilKeyAlreadyPresent new
			indexSelector: selector;
			value: (anObject perform: selector);
			key: aKey;
			signal ]
]

{ #category : #accessing }
SoilDerivedIndex >> at: aValue ifAbsent: aBlock [
	"the object whose attribute is aValue, for a unique index. The value is encoded like the one
	of an added object"
	| key |
	key := [ layout keyFor: aValue primaryKey: nil ]
		on: SoilUnsupportedError
		do: [ :error |
			SoilUnsupportedError signal: 'derived index on #' , selector asString , ': ' , error messageText ].
	^ self newIterator at: key ifAbsent: [ ^ aBlock value ]
]

{ #category : #initialization }
SoilDerivedIndex >> beUnique [
	"every object has its own value: the key is the attribute alone, without the primary key"
	layout := SoilDerivedKeyLayout
		keySize: layout keySize
		unique: true
		primaryKeySize: layout primaryKeySize
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
		uniqueKeys: true;
		yourself.
	"the width of the primary key is set when the index is added to a collection"
	layout := SoilDerivedKeyLayout keySize: 16 unique: false primaryKeySize: 8
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
SoilDerivedIndex >> holdsKey: aKey objectId: anObjectId [
	"whether the entry under aKey points to the object with anObjectId, the one
	a removal would take out"
	| value |
	anObjectId ifNil: [ ^ false ].
	value := self newIterator at: aKey ifAbsent: [ ^ false ].
	^ value asSoilObjectId = anObjectId
]

{ #category : #testing }
SoilDerivedIndex >> includesKey: aKey [
	^ (self newIterator at: aKey ifAbsent: [ nil ]) notNil
]

{ #category : #accessing }
SoilDerivedIndex >> indexKey: aKey [
	"the number the index orders aKey by"
	^ self index indexKey: aKey
]

{ #category : #testing }
SoilDerivedIndex >> isPresentOnDisk [
	^ self index isPresentOnDisk
]

{ #category : #searching }
SoilDerivedIndex >> find: aValue [
	"all objects whose attribute is aValue, in the order of their primary keys"
	^ (self queryFor: aValue) iterator upToEnd
]

{ #category : #testing }
SoilDerivedIndex >> isUnique [
	^ layout isUnique
]

{ #category : #accessing }
SoilDerivedIndex >> keyFor: anObject primaryKey: aByteArray [
	"the key of anObject, a ByteArray of the whole key size. The attribute may not be
	indexable, the error says index and value"
	| value |
	value := anObject perform: selector.
	^ [ layout keyFor: value primaryKey: aByteArray ]
		on: SoilUnsupportedError
		do: [ :error |
			SoilUnsupportedError signal: 'derived index on #' , selector asString , ': ' , error messageText ]
]

{ #category : #accessing }
SoilDerivedIndex >> keySize: anInteger [
	"before the first entry is added: the key size is part of the layout and of the header
	of the index"
	self index keySize: anInteger.
	layout := SoilDerivedKeyLayout
		keySize: anInteger
		unique: layout isUnique
		primaryKeySize: layout primaryKeySize
]

{ #category : #accessing }
SoilDerivedIndex >> layout [
	^ layout
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

{ #category : #accessing }
SoilDerivedIndex >> primaryKeySize: anInteger [
	"the width of the primary key of the collection this index belongs to, which the layout
	puts behind the attribute"
	layout := SoilDerivedKeyLayout
		keySize: layout keySize
		unique: layout isUnique
		primaryKeySize: anInteger
]

{ #category : #searching }
SoilDerivedIndex >> query [
	"a query for the whole index, in key order"
	^ SoilIndexQuery on: self
]

{ #category : #searching }
SoilDerivedIndex >> queryFor: aValue [
	"a query for the entries whose attribute is aValue"
	^ self query range: (self rangeSignalling: [ layout rangeFor: aValue ]); yourself
]

{ #category : #searching }
SoilDerivedIndex >> queryFrom: aLowValue to: aHighValue [
	"a query for the entries whose attribute lies from aLowValue to aHighValue, both included, nil for
	an open end"
	^ self query range: (self rangeSignalling: [ layout rangeFrom: aLowValue to: aHighValue ]); yourself
]

{ #category : #searching }
SoilDerivedIndex >> queryFrom: aLowValue to: aHighValue includeFirst: firstBoolean includeLast: lastBoolean [
	"a query for the entries whose attribute lies between aLowValue and aHighValue, each end
	included or not, nil for an open end"
	^ self query
		range: (self rangeSignalling: [
			layout rangeFrom: aLowValue to: aHighValue includeFirst: firstBoolean includeLast: lastBoolean ]);
		yourself
]

{ #category : #searching }
SoilDerivedIndex >> queryStartingWith: someBytes [
	"a query for the entries whose attribute starts with someBytes, a string or a byte array"
	^ self query range: (self rangeSignalling: [ layout rangeStartingWith: someBytes ]); yourself
]

{ #category : #removing }
SoilDerivedIndex >> removeKey: aKey [
	"takes the entry under aKey out of the index, as SoilIndexedDictionary>>removeKey:ifAbsent: does,
	with the journal entry for the commit"
	| oldValue |
	oldValue := self newIterator removeKey: aKey.
	transaction addJournalEntry: (SoilRemoveKeyEntry new
			segment: [ self segment ];
			id: id;
			key: (self index indexKey: aKey);
			oldValue: oldValue asSoilObjectId).
	^ oldValue
]

{ #category : #private }
SoilDerivedIndex >> rangeSignalling: aBlock [
	"the range aBlock builds from the layout, an error it signals names this index"
	^ aBlock
		on: SoilUnsupportedError
		do: [ :error |
			SoilUnsupportedError signal: 'derived index on #' , selector asString , ': ' , error messageText ]
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
