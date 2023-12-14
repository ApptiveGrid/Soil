Class {
	#name : #SoilBTreeDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #initialization }
SoilBTreeDictionary >> createIndex [ 
	^ SoilBTree new
		initializeHeaderPage;
		valueSize: 8;
		soil: (transaction ifNotNil: [:tr | tr soil]);
		readVersion: (transaction ifNotNil: [:tr | tr readVersion]);
		yourself
]

{ #category : #journal }
SoilBTreeDictionary >> journalEntries [
	| entries segment |
	entries := OrderedCollection new.
	segment := (transaction objectIdOf: self) segment.
	self isRegistered ifFalse: [
		entries add: (SoilNewBTreeListIndexEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			keySize: index keySize;
			valueSize: index valueSize) ].
	newValues keysAndValuesDo: [ :key :value |
		value isInitialized ifFalse: [ SoilIndexOutOfRange signal: 'objectId needs to be initialized before written to journal' ].
		entries add: (SoilAddKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: (self binaryKey: key);
			value: value;
			oldValue: (oldValues at: key ifAbsent: nil)) ].
	removedValues keysAndValuesDo: [ :key :value |
		value isInitialized ifFalse: [ SoilIndexOutOfRange signal: 'objectId needs to be initialized before written to journal' ].
		entries add: (SoilRemoveKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: (self binaryKey: key); 
			oldValue: value) ].
	^ entries
]
