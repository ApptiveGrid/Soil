"
The SoilIndexedDictionary implements a Dictionary that uses an on-disk index.

Keys are created with #asIndexKeyOfSize: with the keySize being configurable when creating the dictionary. 
Values are SoilObjectId instances (8 byte). 

The indexes store data on pages (currently 4kb) on disk. 

Take care: SoilIndexedDictionary needs a transaction before values can be added.
"
Class {
	#name : #SoilIndexedDictionary,
	#superclass : #Object,
	#instVars : [
		'id',
		'transaction',
		'index',
		'newValues',
		'removedValues',
		'oldValues'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilIndexedDictionary class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexedDictionary
]

{ #category : #accessing }
SoilIndexedDictionary class >> soilTransientInstVars [ 
	^ #( index transaction newValues removedValues oldValues)
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
SoilIndexedDictionary >> at: key put: anObject [
	| objectId oldValue |
	objectId := transaction makeRoot: anObject.
	(self newIterator at: key put: objectId) ifNotNil: [ :value |
		oldValue := value ].
	"if there has been a prior removal of the key this new addition invalidates it"
	"removedValues removeKey: key ifAbsent: nil."
	self entryForAddKey: key value: objectId oldValue: oldValue. 
	^ objectId 
]

{ #category : #accessing }
SoilIndexedDictionary >> atIndex: anInteger [
	^ self newIterator atIndex: anInteger
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
SoilIndexedDictionary >> createIndex [
	^ self subclassResponsibility
]

{ #category : #enumerating }
SoilIndexedDictionary >> do: aBlock [
 	self newIterator do: [ :objectId | 
 				aBlock value: objectId ]
]

{ #category : #journal }
SoilIndexedDictionary >> entryForAddKey: key value: value oldValue: oldValue [
	|  segment |
	segment := (transaction objectIdOf: self) segment.
"	value isInitialized ifFalse: [ SoilIndexOutOfRange signal: 'objectId needs to be initialized before written to journal' ].
"	transaction journal addEntry: (SoilAddKeyEntry new 
		segment: segment;
		id: id;
		key: (index indexKey: key);
		value: value;
		oldValue: oldValue) 

]

{ #category : #journal }
SoilIndexedDictionary >> entryForRemoveKey: key  oldValue: oldValue [
		| entries segment |
	entries := OrderedCollection new.
	segment := (transaction objectIdOf: self) segment.
	transaction addJournalEntry: (SoilRemoveKeyEntry new 
			segment: segment;
			id: id;
			key: (index indexKey: key); 
			oldValue: oldValue) .
	^ entries
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

{ #category : #initialization }
SoilIndexedDictionary >> initialize [ 
	super initialize.
	newValues := OrderedDictionary new.
	oldValues := Dictionary new.
	removedValues := OrderedDictionary new.
	id := UUID new asString36.
	index := self createIndex.
]

{ #category : #testing }
SoilIndexedDictionary >> isEmpty [
	^ newValues isEmpty and: [ self newIterator isEmpty ]
]

{ #category : #testing }
SoilIndexedDictionary >> isRegistered [
	^ index isRegistered 
]

{ #category : #journal }
SoilIndexedDictionary >> journalEntries [
	| entries segment |
	entries := OrderedCollection new.
	segment := (transaction objectIdOf: self) segment.
	self isRegistered ifFalse: [
		entries add: (index newIndexEntryClass new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			maxLevel: index maxLevel;
			keySize: index keySize;
			valueSize: index valueSize) ].
	newValues keysAndValuesDo: [ :key :value |
		value isInitialized ifFalse: [ SoilIndexOutOfRange signal: 'objectId needs to be initialized before written to journal' ].
		entries add: (SoilAddKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: (index indexKey: key);
			value: value;
			oldValue: (oldValues at: key ifAbsent: nil)) ].
	removedValues keysAndValuesDo: [ :key :value |
		value isInitialized ifFalse: [ SoilIndexOutOfRange signal: 'objectId needs to be initialized before written to journal' ].
		entries add: (SoilRemoveKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: (index indexKey: key); 
			oldValue: value) ].
	^ entries
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

{ #category : #private }
SoilIndexedDictionary >> prepareNewValues [
	newValues copy keysAndValuesDo: [ :key :object |
		object isObjectId ifFalse: [
			newValues at: key put: (transaction makeRoot: object) ] ]
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
	"might be optimized to not store invalidate add-remove or remove-add"
	| oldValue |
	oldValue := self newIterator removeKey: key ifAbsent: [^ aBlock value].
	self entryForRemoveKey: key  oldValue: oldValue
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

{ #category : #accessing }
SoilIndexedDictionary >> size [ 
	^ self newIterator size

]

{ #category : #serializing }
SoilIndexedDictionary >> soilBasicSerialize: aSerializer [ 
	transaction ifNil: [ 
		transaction := aSerializer transaction.
		self prepareNewValues ].
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndexId: id.
]

{ #category : #serializing }
SoilIndexedDictionary >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction.
	transaction markDirty: self.
	self isRegistered ifFalse: [ 
		aTransaction addJournalEntry: (index newIndexEntry 
			id: id;
			segment: (aTransaction objectIdOf: self) segment) ]
]

{ #category : #serializing }
SoilIndexedDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction.
	"when being materialized newValues is not initialized so we do it here"
	newValues := Dictionary new.
	removedValues := Dictionary new.
	oldValues := Dictionary new
]

{ #category : #serializing }
SoilIndexedDictionary >> soilMaterialized: aMaterializer [
	"connect the global index at materialization time when we
	know the cluster root which defines the location of the index.
	Store a copy-on-write version so all changes are per transaction"
	index := (aMaterializer indexAt: id) asCopyOnWrite
]

{ #category : #accessing }
SoilIndexedDictionary >> values [
	^ self newIterator values
]
