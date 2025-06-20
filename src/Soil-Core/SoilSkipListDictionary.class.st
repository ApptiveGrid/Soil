"
This class implements the SoilIndexDictionary that uses a Lined List as an index.

See the superclass for more informaion about indexed dictionaries

"
Class {
	#name : #SoilSkipListDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListDictionary >> at: key put: anObject [
	| objectId oldValue |
	objectId := transaction makeRoot: anObject.
	(self newIterator at: key put: objectId) ifNotNil: [ :value |
		oldValue := value ].
	"if there has been a prior removal of the key this new addition invalidates it"
	"removedValues removeKey: key ifAbsent: nil."
	self entryForAddKey: key value: objectId oldValue: oldValue. 
	^ objectId 
]

{ #category : #initialization }
SoilSkipListDictionary >> createIndex [ 
	^ SoilSkipList new
		initializeHeaderPage;
		valueSize: 8;
		yourself
]

{ #category : #journal }
SoilSkipListDictionary >> entryForAddKey: key value: value oldValue: oldValue [
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
SoilSkipListDictionary >> entryForRemoveKey: key  oldValue: oldValue [
		| entries segment |
	entries := OrderedCollection new.
	segment := (transaction objectIdOf: self) segment.
	transaction journal add: (SoilRemoveKeyEntry new 
			segment: segment;
			id: id;
			key: (index indexKey: key); 
			oldValue: oldValue) .
	^ entries
]

{ #category : #testing }
SoilSkipListDictionary >> hasIndexUpdates [
	self isRegistered ifFalse: [ ^ true ].
	^ "newValues notEmpty or: [ removedValues notEmpty ]" true
]

{ #category : #testing }
SoilSkipListDictionary >> isEmpty [
	^ self newIterator isEmpty
]

{ #category : #journal }
SoilSkipListDictionary >> journalEntries [
	^ OrderedCollection new
]

{ #category : #removing }
SoilSkipListDictionary >> removeKey: key ifAbsent: aBlock [
	"might be optimized to not store invalidate add-remove or remove-add"
	self newIterator removeKey: key ifAbsent: [^ aBlock value].

]

{ #category : #serializing }
SoilSkipListDictionary >> soilBasicSerialize: aSerializer [ 
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndexId: id.
]

{ #category : #serializing }
SoilSkipListDictionary >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction.
	transaction markDirty: self
]

{ #category : #serializing }
SoilSkipListDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction.

]
