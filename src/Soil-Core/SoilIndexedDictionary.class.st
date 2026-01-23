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
SoilIndexedDictionary >> at: key put: anObject [

	| objectId oldValue |
	objectId := transaction makeRoot: anObject.
	(self newIterator at: key add: objectId) ifNotNil: [ :value |
		oldValue := value ].

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
SoilIndexedDictionary >> isRegistered [
	^ index isRegistered 
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
			value: (SoilRemovedObjectId for: oldValue asSoilObjectId);
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
			value: (SoilRemovedObjectId for: oldValue asSoilObjectId);
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
	aSerializer registerIndex: self
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

]

{ #category : #serializing }
SoilIndexedDictionary >> soilMaterialized: aMaterializer [
	"connect the global index at materialization time when we
	know the cluster root which defines the location of the index.
	Store a copy-on-write version so all changes are per transaction"
	transaction := aMaterializer transaction.
	segment := aMaterializer segment.
	index := (aMaterializer indexAt: id) asCopyOnWrite.
	dirty := false
]

{ #category : #accessing }
SoilIndexedDictionary >> values [
	^ self newIterator values
]
