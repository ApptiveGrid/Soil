Class {
	#name : #SoilSkipListDictionary,
	#superclass : #Object,
	#instVars : [
		'id',
		'transaction',
		'index',
		'newValues',
		'removedValues',
		'oldValues'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListDictionary class >> soilTransientInstVars [ 
	^ #( index transaction newValues removedValues )
]

{ #category : #accessing }
SoilSkipListDictionary >> at: key [ 
	^ self 
		at: key
		ifAbsent: [ KeyNotFound signalFor: key in: self ]

]

{ #category : #accessing }
SoilSkipListDictionary >> at: key ifAbsent: aBlock [
	| objectId |
	^ transaction 
		ifNotNil: [  
			objectId := (self basicAt: key ifAbsent: [ ^ aBlock value ]) asSoilObjectId.
			transaction proxyForObjectId: objectId ]
		ifNil: [ newValues at: key ifAbsent: aBlock ]
]

{ #category : #accessing }
SoilSkipListDictionary >> at: key put: anObject [
	| objectId iterator |
	^ transaction 
		ifNotNil: [
			objectId := transaction makeRoot: anObject.
			"binKey := (key asSkipListKeyOfSize: index keySize) asInteger."
			transaction markDirty: self.
			iterator := self index newIterator.
			(iterator at: key put: objectId) ifNotNil: [ :value |
				oldValues 
					at: key
					ifAbsentPut: objectId ].
		"if there has been a prior removal of the key this new
		addition invalidates it"
			removedValues removeKey: key ifAbsent: [  ].
			newValues at: key put: objectId. ]
		ifNil: [ 
			newValues at: key put: anObject ]
]

{ #category : #accessing }
SoilSkipListDictionary >> atIndex: anInteger [
	^ transaction 
		ifNotNil: [  
			(self index atIndex: anInteger)
				ifNotNil: [ :bytes |
					transaction 
						objectId: bytes asSoilObjectId
						ifVisible: [:objectId | (objectId asSoilObjectProxy) transaction: transaction ]
						ifHidden: [ nil ] ] ]
		ifNil: [ (newValues associations at: anInteger) value  ]
]

{ #category : #accessing }
SoilSkipListDictionary >> basicAt: aString ifAbsent: aBlock [ 
	| iterator value key |
	key := (aString asSkipListKeyOfSize: self index keySize) asInteger.
	iterator := self index newIterator.
	value := iterator at: aString ifAbsent: [ aBlock value ].
	value isInitialized ifFalse: [  
		^ (iterator currentPage isOlderThan: transaction readVersion) 
			ifTrue: [ aBlock value ] 
			ifFalse: [
				(transaction 
					journalEntriesFor: key 
					inIndex: index 
					startingAt: iterator currentPage lastTransaction)
						ifNotEmpty: [:entries | 
							entries last oldValue ]
						ifEmpty: [ self halt. ] ] ].
	"if the last modifying transaction of the current page is smaller
	than ours then we don't need to check for visibility as all objects
	are visible"
	^ (iterator currentPage isOlderThan: transaction readVersion)
		ifTrue: [ value ]
		ifFalse: [ 
			(transaction 
				journalEntriesFor: key 
				inIndex: index 
				startingAt: iterator currentPage lastTransaction)
					ifNotEmpty: [:entries | 
						entries last oldValue ifNil: [ aBlock value ] ]
					ifEmpty: [ value ].
			 ]
	
]

{ #category : #accessing }
SoilSkipListDictionary >> binaryKey: aString [
	^ (aString asSkipListKeyOfSize: self index keySize) asInteger
]

{ #category : #enumerating }
SoilSkipListDictionary >> do: aBlock [

	| iterator assoc |
	transaction
		ifNotNil: [ 
			iterator := self index newIterator.
			[ (assoc := iterator nextAssociation) notNil ] whileTrue: [ 
				(self
					 restoreValue: assoc value
					 forKey: assoc key
					 iterator: iterator) ifNotNil: [ :objectId | 
					aBlock value: (transaction proxyForObjectId: objectId) ] ] ]
		ifNil: [ 
			newValues values do: [ :each | 
				aBlock value: (each isObjectId
						 ifTrue: [ transaction objectWithId: each ]
						 ifFalse: [ each ]) ] ]
]

{ #category : #accessing }
SoilSkipListDictionary >> first [
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: self index first ]
		ifNil: [ newValues associations first value ]
]

{ #category : #accessing }
SoilSkipListDictionary >> first: anInteger [ 
	^ transaction 
		ifNotNil: [ 
			(self index first: anInteger) 
				collect: [ :each | self proxyFromByteArray: each ] ]
		ifNil: [ (newValues associations first: anInteger) collect: #value ]  
]

{ #category : #accesing }
SoilSkipListDictionary >> firstAssociation [
	self index isRegistered ifFalse: [ 
		^ newValues at: (newValues keyAtIndex: 1) ].
	^ index newIterator firstAssociation ifNotNil: [ :assoc | 
			assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]

]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> historicValueAt: key iterator: iterator ifAbsent: absentBlock [ 
	"a removed value will return ObjectId 0:0"
	
	^ (iterator currentPage isOlderThan: transaction readVersion) 
		ifTrue: [ 
			"all modifications to this page have been done before we
			started the transaction, so the removal is visibile and 
			value absent"
			absentBlock value ] 
		ifFalse: [
			"we determine all changes between our transaction and the
			last one modifying the page. if we get back changes for the
			key the value of the oldes entry has the value it had before"
			(transaction 
				journalEntriesFor: key 
				inIndex: index 
				startingAt: iterator currentPage lastTransaction)
					ifNotEmpty: [:entries | entries last oldValue ]
					ifEmpty: [ absentBlock value ] ]
	
]

{ #category : #accessing }
SoilSkipListDictionary >> id [
	^ id
]

{ #category : #accessing }
SoilSkipListDictionary >> index [
	^ index
]

{ #category : #initialization }
SoilSkipListDictionary >> initialize [ 
	super initialize.
	newValues := OrderedDictionary new.
	oldValues := Dictionary new.
	removedValues := OrderedDictionary new.
	id := UUID new asString36.
	index := SoilSkipList new
		initializeHeaderPage;
		valueSize: 8;
		yourself
]

{ #category : #testing }
SoilSkipListDictionary >> isEmpty [
	newValues ifNotEmpty: [ ^ false ].
	^ self index isEmpty
]

{ #category : #testing }
SoilSkipListDictionary >> isRegistered [
	^ index isRegistered 
]

{ #category : #'as yet unclassified' }
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
			oldValue: (oldValues at: key ifAbsent: [nil ])) ].
	removedValues keysAndValuesDo: [ :key :value |
		entries add: (SoilRemoveKeyEntry new 
			transactionId: transaction writeVersion;
			segment: segment;
			id: id;
			key: (self binaryKey: key); 
			oldValue: value) ].
	^ entries
]

{ #category : #accessing }
SoilSkipListDictionary >> keySize: anInteger [ 
	index keySize: anInteger 
]

{ #category : #accessing }
SoilSkipListDictionary >> last [
	| assoc |
	^ transaction 
		ifNotNil: [  
			assoc := self index newIterator lastAssociation.
			assoc ifNil: [ ^ nil ].
			assoc value isRemoved ifTrue: [ ^ nil ].
			assoc key -> (transaction proxyForObjectId: assoc value asSoilObjectId) ]
		ifNil: [ newValues associations last value ]
]

{ #category : #accessing }
SoilSkipListDictionary >> lastAssociation [
	^ self index newIterator lastAssociation ifNotNil: [ :assoc | 
		assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]

]

{ #category : #private }
SoilSkipListDictionary >> loadFrom: aFileReference [ 
	^ SoilSkipList new 
		path: aFileReference;
		open
]

{ #category : #accessing }
SoilSkipListDictionary >> maxLevel: anInteger [ 
	index maxLevel: anInteger.

]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> nextAfter: key [  
	| iterator |
	iterator := self index newIterator 
		find: key asInteger;
		yourself.
	^ iterator nextAssociation 
		ifNotNil: [ :assoc |
			assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> prepareNewValues [
	newValues copy keysAndValuesDo: [ :key :object |
		object isObjectId ifFalse: [
			newValues at: key put: (transaction makeRoot: object) ] ]
]

{ #category : #printing }
SoilSkipListDictionary >> printOn: aStream [ 
	super printOn: aStream.
	aStream << ' id=' << id asString
]

{ #category : #enumerating }
SoilSkipListDictionary >> proxyFromByteArray: aByteArray [
	
	^ transaction proxyForObjectId: aByteArray asSoilObjectId
]

{ #category : #removing }
SoilSkipListDictionary >> removeKey: key [
	^ self 
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilSkipListDictionary >> removeKey: key ifAbsent: aBlock [
	| iterator v |
	^ transaction 
		ifNotNil: [ 
			"remove from newValues as there could be a new at:put: on that
			key but removing the key will remove the value again"
			newValues removeKey: key ifAbsent: [ ].
			transaction markDirty: self.
			iterator := self index newIterator.
			v := iterator at: key ifAbsent: [ Error signal ].
			removedValues 
				at: key 
				put: v asSoilObjectId.
			iterator at: key put: (SoilObjectId segment: 0 index: 0) ]
		ifNil: [ 
			removedValues 
				at: key
				put: (newValues removeKey: key ifAbsent: [ ^ aBlock value ]) ]
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> restoreValue: value forKey: key iterator: iterator [ 
	"restore a value that has been removed by a later 
	transaction"
	^ value isRemoved 
		ifTrue: [
			self 
				historicValueAt: key 
				iterator: iterator 
				ifAbsent: [ nil ] ]
		ifFalse: [
			"restore a value that has been overwritten by a later
			transaction"   
			self 
				historicValueAt: key 
				iterator: iterator 
				ifAbsent: [ value ] ]
]

{ #category : #accessing }
SoilSkipListDictionary >> second [
	^ transaction 
		ifNotNil: [ index newIterator first; next ]
		ifNil: [ newValues associations second value ]
]

{ #category : #accessing }
SoilSkipListDictionary >> size [ 
	^ transaction 
		ifNotNil: [ self index size ]
		ifNil: [ newValues size ]
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilBasicSerialize: aSerializer [ 
	transaction ifNil: [ 
		transaction := aSerializer transaction.
		self prepareNewValues ].
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndexId: id.
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction.
	newValues copy keysAndValuesDo: [ :key :object | | obj |
		obj := object isObjectId
			ifTrue: [ object ] 
			ifFalse: [
				newValues 
					at: key 
					put: (transaction makeRoot: object) ].
		self index newIterator at: key put: obj ].
	transaction markDirty: self
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction.
	"when being materialized newValues is not initialized so we do it here"
	newValues := Dictionary new.
	removedValues := Dictionary new.
	oldValues := Dictionary new
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilMaterialized: aMaterializer [
	"connect the global index at materialization time when we
	know the cluster root which defines the location of the index.
	Store a copy-on-write version so all changes are per transaction"
	index := (aMaterializer indexAt: id) asCopyOnWrite
]

{ #category : #accessing }
SoilSkipListDictionary >> values [
	| col |
	col := OrderedCollection new.
	self do: [ :each | col add: each ].
	^ col
]
