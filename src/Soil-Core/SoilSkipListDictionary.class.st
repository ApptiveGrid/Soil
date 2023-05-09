Class {
	#name : #SoilSkipListDictionary,
	#superclass : #Object,
	#instVars : [
		'id',
		'transaction',
		'index',
		'newValues',
		'removedValues'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListDictionary class >> soilTransientInstVars [ 
	^ #( index transaction newValues )
]

{ #category : #accessing }
SoilSkipListDictionary >> at: key [ 
	^ self 
		at: key
		ifAbsent: [ KeyNotFound signal: key asString, ' not found' ]

]

{ #category : #accessing }
SoilSkipListDictionary >> at: key ifAbsent: aBlock [
	| objectId |
	^ transaction 
		ifNotNil: [  
			objectId := (self index at: key ifAbsent: [ ^ aBlock value ]) asSoilObjectId.
			transaction proxyForObjectId: objectId ]
		ifNil: [ newValues at: key ifAbsent: aBlock ]
]

{ #category : #accessing }
SoilSkipListDictionary >> at: key put: anObject [
	| objectId |
	transaction ifNotNil: [
		objectId := transaction makeRoot: anObject.
		transaction markDirty: self.
		self index at: key put: objectId.
		"if there has been a prior removal of the key this new
		addition invalidates it"
		removedValues removeKey: key ifAbsent: [  ]. 
		^ newValues at: key put: objectId ].
	newValues at: key put: anObject.

]

{ #category : #accessing }
SoilSkipListDictionary >> atIndex: anInteger [
	^ transaction 
		ifNotNil: [  
			(self index atIndex: anInteger)
				ifNotNil: [ :bytes | self proxyFromByteArray: bytes ] ]
		ifNil: [ (newValues associations at: anInteger) value  ]
]

{ #category : #enumerating }
SoilSkipListDictionary >> do: aBlock [ 
	transaction 
		ifNotNil: [  
			self index do: [ :byteArrayOrObjectId |
				aBlock value: (transaction proxyForObjectId: byteArrayOrObjectId asSoilObjectId ) ] ]
		ifNil: [.
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

{ #category : #accessing }
SoilSkipListDictionary >> id [
	^ id
]

{ #category : #accessing }
SoilSkipListDictionary >> index [
	^ index ifNil: [ 
		index := self lookupIndex asCopyOnWrite  ]
]

{ #category : #initialization }
SoilSkipListDictionary >> initialize [ 
	super initialize.
	newValues := OrderedDictionary new.
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
	| entries |
	entries := OrderedCollection new.
	newValues keysAndValuesDo: [ :key :value |
		entries add: (SoilNewKeyEntry new 
			indexId: id;
			key: key;
			value: value) ].
	removedValues keysAndValuesDo: [ :key :value |
		entries add: (SoilRemoveKeyEntry new 
			indexId: id;
			key: key; 
			value: value) ].
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
			assoc := self index last.
			assoc ifNil: [ ^ nil ].
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

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> lookupIndex [
	^ transaction 
		indexAt: self
		ifAbsent: [ self newIndexInstance ]
]

{ #category : #accessing }
SoilSkipListDictionary >> maxLevel: anInteger [ 
	index maxLevel: anInteger.

]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> newIndexInstance [
	self halt.
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> nextAfter: key [  
	| page |
	page := self index newIterator find: key asInteger;  page.
	^ (page itemAfter: key asInteger)
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
		ifAbsent: [ KeyNotFound signalFor: key ]
]

{ #category : #removing }
SoilSkipListDictionary >> removeKey: key ifAbsent: aBlock [
	^ transaction 
		ifNotNil: [ 
			"remove from newValues as there could be a new at:put: on that
			key but removing the key will remove the value again"
			newValues removeKey: key ifAbsent: [ ].
			transaction markDirty: self.
			removedValues 
				at: key 
				put: (self index 
					removeKey: key 
					ifAbsent: [ ^ aBlock value ]) asSoilObjectId ]
		ifNil: [ 
			removedValues 
				at: key
				put: (newValues removeKey: key ifAbsent: [ ^ aBlock value ]) ]
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
	self isRegistered ifFalse: [  
		index := (aSerializer registerIndexedObject: self) asCopyOnWrite  ]
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
		self index at: key put: obj ].
	transaction markDirty: self
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction.
	"when being materialized newValues is not initialized so we do it here"
	newValues := Dictionary new 
]

{ #category : #accessing }
SoilSkipListDictionary >> values [
	| col |
	col := OrderedCollection new.
	self do: [ :each | col add: each ].
	^ col
]
