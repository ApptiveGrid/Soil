"
This class implements the SoilIndexDictionary that uses a B+Tree.

See the superclass for more informaion about indexed dictionaries
"
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
