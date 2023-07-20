Class {
	#name : #SoilBTreeDictionary,
	#superclass : #SoilSkipListDictionary,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #initialization }
SoilBTreeDictionary >> initialize [ 
	newValues := OrderedDictionary new.
	oldValues := Dictionary new.
	removedValues := OrderedDictionary new.
	id := UUID new asString36.
	index := SoilBTree new
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
		entries add: (SoilAddKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: key;
			value: value;
			oldValue: (oldValues at: key ifAbsent: [nil ])) ].
	removedValues keysAndValuesDo: [ :key :value |
		entries add: (SoilRemoveKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: key; 
			oldValue: value) ].
	^ entries
]
