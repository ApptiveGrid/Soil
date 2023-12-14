Class {
	#name : #SoilSkipListDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #initialization }
SoilSkipListDictionary >> createIndex [ 
	^ SoilSkipList new
		initializeHeaderPage;
		valueSize: 8;
		soil: (transaction ifNotNil: [:tr | tr soil]);
		readVersion: (transaction ifNotNil: [:tr | tr readVersion]);
		yourself
]

{ #category : #journal }
SoilSkipListDictionary >> journalEntries [
	| entries segment |
	entries := OrderedCollection new.
	segment := (transaction objectIdOf: self) segment.
	self isRegistered ifFalse: [
		entries add: (SoilNewSkipListIndexEntry new 
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
