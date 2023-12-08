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
	| objectId |
	^ transaction 
		ifNotNil: [  
			objectId := (self basicAt: key ifAbsent: [ ^ aBlock value ]) asSoilObjectId.
			transaction proxyForObjectId: objectId ]
		ifNil: [ newValues at: key ifAbsent: aBlock ]
]

{ #category : #accessing }
SoilIndexedDictionary >> at: key put: anObject [
	^ transaction 
		ifNotNil: [ 
			| objectId iterator |
			objectId := transaction makeRoot: anObject.
			iterator := self index newIterator.
			(iterator at: key put: objectId) ifNotNil: [ :value |
				oldValues 
					at: key
					ifAbsentPut: objectId ].
		"if there has been a prior removal of the key this new addition invalidates it"
			removedValues removeKey: key ifAbsent: nil.
			newValues at: key put: objectId. ]
		ifNil: [ 
			newValues at: key put: anObject ]
]

{ #category : #accessing }
SoilIndexedDictionary >> atIndex: anInteger [
	^ transaction 
		ifNotNil: [  
			(self index atIndex: anInteger)
				ifNotNil: [ :bytes |
					transaction 
						objectId: bytes asSoilObjectId
						ifVisible: [:objectId | (objectId asSoilObjectProxy) transaction: transaction ]
						ifHidden: nil ] ]
		ifNil: [ (newValues associations at: anInteger) value  ]
]

{ #category : #accessing }
SoilIndexedDictionary >> basicAt: aString ifAbsent: aBlock [ 
	| iterator value key |
	key := (aString asSkipListKeyOfSize: self index keySize) asInteger.
	iterator := self index newIterator.
	value := iterator at: aString ifAbsent: aBlock.
	^ (self restoreValue: value forKey: key iterator: iterator) ifNil: [ aBlock value ]
]

{ #category : #accessing }
SoilIndexedDictionary >> binaryKey: aString [
	^ (aString asSkipListKeyOfSize: self index keySize) asInteger
]

{ #category : #initialization }
SoilIndexedDictionary >> createIndex [
	^ self subclassResponsibility
]

{ #category : #enumerating }
SoilIndexedDictionary >> do: aBlock [

	transaction
		ifNotNil: [ 
			| iterator assoc |
			iterator := self index newIterator.
			[ (assoc := iterator nextAssociation) notNil ] whileTrue: [ 
				(self
					 restoreValue: assoc value
					 forKey: assoc key
					 iterator: iterator) ifNotNil: [ :objectId | 
					aBlock value: (transaction proxyForObjectId: objectId) ] ] ]
		ifNil: [ 
			newValues valuesDo: [ :each | aBlock value: each ] ]
]

{ #category : #accessing }
SoilIndexedDictionary >> first [
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: self index newIterator first ]
		ifNil: [ 
			self newValuesSortedByKeyOrder ifNotEmpty: [:nv | nv first value ] ifEmpty: nil]
]

{ #category : #accessing }
SoilIndexedDictionary >> first: anInteger [ 
	^ transaction 
		ifNotNil: [ 
			(self index first: anInteger) 
				collect: [ :each | self proxyFromByteArray: each ] ]
		ifNil: [ (self newValuesSortedByKeyOrder first: anInteger) collect: #value ]  
]

{ #category : #accessing }
SoilIndexedDictionary >> firstAssociation [

	^ transaction
		  ifNotNil: [
			  index newIterator firstAssociation ifNotNil: [ :assoc |
				  assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ] ]
		  ifNil: [
			self newValuesSortedByKeyOrder ifNotEmpty: [:nv | nv first ] ifEmpty: nil]
]

{ #category : #testing }
SoilIndexedDictionary >> hasIndexUpdates [
	self isRegistered ifFalse: [ ^ true ].
	^ newValues notEmpty or: [ removedValues notEmpty ]
]

{ #category : #accessing }
SoilIndexedDictionary >> historicValueAt: key iterator: iterator ifAbsent: absentBlock [ 
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
					ifEmpty: absentBlock ]
	
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
	| iterator|
	iterator := self index newIterator.
	iterator currentPage: self index firstPage.
	^ newValues isEmpty and: [ self index isEmpty 
		or: [
		"all items might be removed and not restorable" 
		(self index firstPage items allSatisfy: [ :each | (self
					 restoreValue: each value
					 forKey: each key
					 iterator: iterator)isNil] )]]
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
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: self index newIterator last ]
		ifNil: [ 
			self newValuesSortedByKeyOrder ifNotEmpty: [:nv | nv last value ] ifEmpty: nil ]
]

{ #category : #accessing }
SoilIndexedDictionary >> lastAssociation [

	^ transaction
		  ifNotNil: [
			  index newIterator lastAssociation ifNotNil: [ :assoc |
				  assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ] ]
		  ifNil: [ 
			self newValuesSortedByKeyOrder ifNotEmpty: [:nv | nv last ] ifEmpty: nil ]
]

{ #category : #private }
SoilIndexedDictionary >> loadFrom: aFileReference [ 
	^ SoilSkipList new 
		path: aFileReference;
		open
]

{ #category : #accessing }
SoilIndexedDictionary >> maxLevel: anInteger [ 
	index maxLevel: anInteger.

]

{ #category : #accessing }
SoilIndexedDictionary >> newValuesSortedByKeyOrder [

	^ newValues associations sort: [ :a :b |
		(a key asSkipListKeyOfSize: self index keySize) asInteger 
		< (b key asSkipListKeyOfSize: self index keySize) asInteger ]
]

{ #category : #accessing }
SoilIndexedDictionary >> nextAfter: key [  
	| iterator |
	transaction ifNil: [ 
		| newValueSorted |
		newValueSorted := self newValuesSortedByKeyOrder.
		^ (newValueSorted after: (newValues associationAt: key)) value  ].

	iterator := self index newIterator 
		find: key asInteger;
		yourself.
	^ iterator nextPresentAssociation 
		ifNotNil: [ :assoc |
			assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]
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

{ #category : #enumerating }
SoilIndexedDictionary >> proxyFromByteArray: aByteArray [
	
	^ transaction proxyForObjectId: aByteArray asSoilObjectId
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key [
	^ self 
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key ifAbsent: aBlock [
	| iterator v |
	^ transaction 
		ifNotNil: [ 
			"remove from newValues as there could be a new at:put: on that
			key but removing the key will remove the value again"
			newValues removeKey: key ifAbsent: nil.
			iterator := self index newIterator.
			v := self basicAt: key ifAbsent: [^ aBlock value].
			removedValues 
				at: key 
				put: v asSoilObjectId.
			iterator removeKey: key ]
		ifNil: [ 
			removedValues 
				at: key
				put: (newValues removeKey: key ifAbsent: [ ^ aBlock value ]) ]
]

{ #category : #private }
SoilIndexedDictionary >> restoreValue: value forKey: key iterator: iterator [
	"restore a value that has been removed by a later transaction"
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
SoilIndexedDictionary >> second [
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: (index newIterator first; next) ]
		ifNil: [ self newValuesSortedByKeyOrder second value ]
]

{ #category : #accessing }
SoilIndexedDictionary >> size [ 
	^ transaction 
		ifNotNil: [ 
			"We should just call size on index, but the do: here can restore values"
			| sum |
			sum := 0.
			self do: [ :each | sum := sum + 1 ].
			sum ]
		ifNil: [ newValues size ]
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
	| col |
	col := OrderedCollection new.
	self do: [ :each | col add: each ].
	^ col
]
