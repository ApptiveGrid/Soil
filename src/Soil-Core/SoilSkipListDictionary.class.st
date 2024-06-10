"
This class implements the SoilIndexDictionary that uses a Lined List as an index.

See the superclass for more informaion about indexed dictionaries

"
Class {
	#name : #SoilSkipListDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #rewriting }
SoilSkipListDictionary >> compact [ 
	"Rewrite index file without removed items"
	self rewriteUsing: [ :item | item ]
]

{ #category : #initialization }
SoilSkipListDictionary >> createIndex [ 
	^ SoilSkipList new
		initializeHeaderPage;
		valueSize: 8;
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

{ #category : #rewriting }
SoilSkipListDictionary >> rewriteUsing: aBlock [
	| skipList |
	"write new index file and add all items. Use aBlock to 
	enable converting items"
	skipList := index wrapped.
	SoilPluggableIndexRewriter new 
		index: index wrapped;
		indexBlock: [ :idx | idx  ];
		itemBlock: aBlock;
		cleanRemoved;
		run
]
