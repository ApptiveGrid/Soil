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
	| found |
	found := self basicAt: key ifAbsent: [ ^ aBlock value ].
	^ transaction proxyForObjectId: found asSoilObjectId
]

{ #category : #accessing }
SoilIndexedDictionary >> at: key put: anObject [
	| objectId |
	objectId := transaction makeRoot: anObject.
	(self newIterator at: key put: objectId) ifNotNil: [ :value |
		oldValues 
			at: key
			ifAbsentPut: objectId ].
	"if there has been a prior removal of the key this new addition invalidates it"
	removedValues removeKey: key ifAbsent: nil.
	^ newValues at: key put: objectId

]

{ #category : #accessing }
SoilIndexedDictionary >> atIndex: anInteger [
	^ (self newIterator atIndex: anInteger)
				ifNotNil: [ :objectId | transaction proxyForObjectId: objectId ]

]

{ #category : #accessing }
SoilIndexedDictionary >> basicAt: aString ifAbsent: aBlock [ 
	^ self newIterator at: aString ifAbsent: aBlock
]

{ #category : #accessing }
SoilIndexedDictionary >> binaryKey: aString [
	^ (aString asIndexKeyOfSize: index keySize) asInteger
]

{ #category : #initialization }
SoilIndexedDictionary >> createIndex [
	^ self subclassResponsibility
]

{ #category : #enumerating }
SoilIndexedDictionary >> do: aBlock [
 	self newIterator do: [ :objectId | 
 				aBlock value: (transaction proxyForObjectId: objectId) ]
]

{ #category : #accessing }
SoilIndexedDictionary >> first [
	^ self proxyFromByteArray: self newIterator first
]

{ #category : #accessing }
SoilIndexedDictionary >> first: anInteger [

	^ (self newIterator first: anInteger) collect: [ :each |
		  self proxyFromByteArray: each ]
]

{ #category : #accessing }
SoilIndexedDictionary >> firstAssociation [
	"Note: key will be binary key"
	^ self newIterator firstAssociation ifNotNil: [ :assoc |
			assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]
]

{ #category : #testing }
SoilIndexedDictionary >> hasIndexUpdates [
	self isRegistered ifFalse: [ ^ true ].
	^ newValues notEmpty or: [ removedValues notEmpty ]
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
	^ newValues isEmpty and: [ self newIterator isEmpty ]
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
	^ self proxyFromByteArray: self newIterator last
	
]

{ #category : #accessing }
SoilIndexedDictionary >> lastAssociation [
	"Note: key will be binary key"
	^ self newIterator lastAssociation ifNotNil: [ :assoc |
				 assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ] 

]

{ #category : #private }
SoilIndexedDictionary >> loadFrom: aFileReference [ 
	^ SoilSkipList new 
		path: aFileReference;
		open
]

{ #category : #accessing }
SoilIndexedDictionary >> maxLevel: anInteger [
	"Implemented here to allow to switch between SkipList and BTree easily in tests"
	index maxLevel: anInteger

]

{ #category : #private }
SoilIndexedDictionary >> newIterator [
	^ index newIterator
			soil: transaction soil;
			readVersion: transaction readVersion
]

{ #category : #accessing }
SoilIndexedDictionary >> nextAfter: key [  
	^ (self nextAssociationAfter: key) value  

]

{ #category : #accessing }
SoilIndexedDictionary >> nextAssociationAfter: key [  
	"Note: key will be binary key"
	^ (self newIterator nextAssociationAfter: key)
		ifNotNil: [ :assoc |
			assoc key -> (transaction objectWithId: assoc value asSoilObjectId) ]
]

{ #category : #private }
SoilIndexedDictionary >> nextCloseTo: aKey [ 
	^ transaction objectWithId: (self newIterator nextCloseTo: aKey) 
]

{ #category : #private }
SoilIndexedDictionary >> nextKeyCloseTo: aKey [
	"Note: key will be binary key"
	^ self newIterator nextKeyCloseTo: aKey
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
	 | v |
	"remove from newValues as there could be a new at:put: on that
	key but removing the key will remove the value again"
	newValues removeKey: key ifAbsent: nil.
	v := self basicAt: key ifAbsent: [^ aBlock value].
	removedValues 
			at: key 
			put: v asSoilObjectId.
	^ self newIterator removeKey: key
]

{ #category : #accessing }
SoilIndexedDictionary >> second [
	^ self proxyFromByteArray: (self newIterator first; next)
]

{ #category : #accessing }
SoilIndexedDictionary >> size [ 
	^ self newIterator size

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
		self newIterator at: key put: obj ].
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
	^ self newIterator values collect: [ :each | self proxyFromByteArray: each ]
]
