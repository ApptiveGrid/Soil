"
The SoilIndexedDictionary implements a Dictionary that uses an on-disk index.

Keys are created with #asIndexKeyOfSize: with the keySize being configurable when creating the dictionary. 
Values are SoilObjectId instances (8 byte). 

The indexes store data on pages (currently 4kb) on disk. 

Take care: SoilIndexedDictionary needs a transaction before values can be added.
"
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
	^ self 
		basicAt: key 
		ifAbsent: aBlock
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
	^ self newIterator atIndex: anInteger
]

{ #category : #accessing }
SoilIndexedDictionary >> basicAt: aString ifAbsent: aBlock [ 
	^ self newIterator at: aString ifAbsent: aBlock
]

{ #category : #initialization }
SoilIndexedDictionary >> createIndex [
	^ self subclassResponsibility
]

{ #category : #enumerating }
SoilIndexedDictionary >> do: aBlock [
 	self newIterator do: [ :objectId | 
 				aBlock value: objectId ]
]

{ #category : #accessing }
SoilIndexedDictionary >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilIndexedDictionary >> first: anInteger [

	^ self newIterator first: anInteger
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
	^ self newIterator last
	
]

{ #category : #accessing }
SoilIndexedDictionary >> last: anInteger [
	^ self newIterator last: anInteger
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
		returnProxyForTransaction: transaction;
		journal: transaction soil journal;
		readVersion: transaction readVersion 

]

{ #category : #accessing }
SoilIndexedDictionary >> nextAfter: key [  
	^  self newIterator nextAfter: key
]

{ #category : #private }
SoilIndexedDictionary >> nextCloseTo: aKey [ 
	^ self newIterator nextCloseTo: aKey 
]

{ #category : #'as yet unclassified' }
SoilIndexedDictionary >> persistentIndex [
	^ index persistentIndex 
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

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key [
	^ self 
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndexedDictionary >> removeKey: key ifAbsent: aBlock [
	 | v newValueRemoved |
	"remove from newValues as there could be a new at:put: on that
	key but removing the key will remove the value again"
	newValueRemoved := (newValues removeKey: key ifAbsent: nil) notNil.
	v := self newIterator removeKey: key ifAbsent: [^ aBlock value].
	"remove value and therefor create a journal entry only if it has not been 
	in newValues which removes just a freshly added key again"
	newValueRemoved ifFalse: [
		removedValues 
			at: key 
			put: v asSoilObjectId ].
	^v
]

{ #category : #enumerating }
SoilIndexedDictionary >> reverseDo: aBlock [
 	self newIterator reverseDo: [ :objectId | 
 				aBlock value: objectId ]
]

{ #category : #accessing }
SoilIndexedDictionary >> second [
	^ self newIterator first; next
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
	^ self newIterator values
]
