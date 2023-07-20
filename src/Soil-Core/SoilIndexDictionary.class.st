Class {
	#name : #SoilIndexDictionary,
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

{ #category : #accessing }
SoilIndexDictionary >> at: key [ 
	^ self 
		at: key
		ifAbsent: [ KeyNotFound signalFor: key in: self ]

]

{ #category : #accessing }
SoilIndexDictionary >> at: key ifAbsent: aBlock [
	
	^ transaction 
		ifNotNil: [  
			| objectId |
			objectId := (self basicAt: key ifAbsent: [ ^ aBlock value ]) asSoilObjectId.
			transaction proxyForObjectId: objectId ]
		ifNil: [ newValues at: key ifAbsent: aBlock ]
]

{ #category : #accessing }
SoilIndexDictionary >> at: key put: anObject [
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
SoilIndexDictionary >> atIndex: anInteger [
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
SoilIndexDictionary >> basicAt: aString ifAbsent: aBlock [ 
	| iterator value key |
	key := (aString asSkipListKeyOfSize: self index keySize) asInteger.
	iterator := self index newIterator.
	value := iterator at: aString ifAbsent: [ aBlock value ].
	value isRemoved ifTrue: [  
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
SoilIndexDictionary >> binaryKey: aString [
	^ (aString asSkipListKeyOfSize: self index keySize) asInteger
]

{ #category : #enumerating }
SoilIndexDictionary >> do: aBlock [

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
			newValues valuesDo: [ :each | 
				aBlock value: (each isObjectId
						 ifTrue: [ transaction objectWithId: each ]
						 ifFalse: [ each ]) ] ]
]

{ #category : #accessing }
SoilIndexDictionary >> first [
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: self index newIterator first ]
		ifNil: [ 
			"associations is sorted"
			newValues associations ifNotEmpty: [:nv | nv first value ] ifEmpty: nil]
]

{ #category : #accessing }
SoilIndexDictionary >> first: anInteger [ 
	^ transaction 
		ifNotNil: [ 
			(self index first: anInteger) 
				collect: [ :each | self proxyFromByteArray: each ] ]
		ifNil: [ (newValues associations first: anInteger) collect: #value ]  
]

{ #category : #accessing }
SoilIndexDictionary >> firstAssociation [

	^ transaction
		  ifNotNil: [
			  index newIterator firstAssociation ifNotNil: [ :assoc |
				  assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ] ]
		  ifNil: [ 
			"associations is sorted" 
			newValues associations ifNotEmpty: [:nv | nv first ] ifEmpty: nil]
]

{ #category : #accessing }
SoilIndexDictionary >> id [
	^ id
]

{ #category : #accessing }
SoilIndexDictionary >> index [
	^ index
]

{ #category : #accessing }
SoilIndexDictionary >> keySize: anInteger [ 
	index keySize: anInteger 
]

{ #category : #accessing }
SoilIndexDictionary >> last [
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: self index newIterator last ]
		ifNil: [ 
			"associations is sorted"
			newValues associations ifNotEmpty: [:nv | nv last value ] ifEmpty: nil ]
]

{ #category : #accessing }
SoilIndexDictionary >> lastAssociation [

	^ transaction
		  ifNotNil: [
			  index newIterator lastAssociation ifNotNil: [ :assoc |
				  assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ] ]
		  ifNil: [ 
			"associations is sorted" 
			newValues associations ifNotEmpty: [:nv | nv last ] ifEmpty: nil ]
]

{ #category : #accessing }
SoilIndexDictionary >> maxLevel: anInteger [ 
	index maxLevel: anInteger.

]

{ #category : #accessing }
SoilIndexDictionary >> nextAfter: key [  
	| iterator |
	transaction ifNil: [ 
		| newValueSorted |
		self flag: #TODO. "need to sort in key order"
		newValueSorted := newValues associations.
		^ (newValueSorted after: (newValues associationAt: key)) value  ].

	iterator := self index newIterator 
		find: key asInteger;
		yourself.
	^ iterator nextPresentAssociation 
		ifNotNil: [ :assoc |
			assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]
]

{ #category : #enumerating }
SoilIndexDictionary >> proxyFromByteArray: aByteArray [
	
	^ transaction proxyForObjectId: aByteArray asSoilObjectId
]

{ #category : #accessing }
SoilIndexDictionary >> second [
	^ transaction 
		ifNotNil: [ self proxyFromByteArray: (index newIterator first; next) ]
		ifNil: [ newValues associations second value ]
]

{ #category : #accessing }
SoilIndexDictionary >> size [ 
	^ transaction 
		ifNotNil: [ self index size ]
		ifNil: [ newValues size ]
]

{ #category : #accessing }
SoilIndexDictionary >> values [
	| col |
	col := OrderedCollection new.
	self do: [ :each | col add: each ].
	^ col
]
