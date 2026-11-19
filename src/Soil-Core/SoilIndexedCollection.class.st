"
A SoilIndexedCollection is a collection of objects that is reachable through
several indexes at once. The primary index (#primary:) is unique and holds every
element under its primary key. Every SoilDerivedIndex added with #addIndex: derives
its own key from the objects that are added, so the same object can be looked up by
different properties; behind the attribute its key carries the primary key of the
element. The primary index has to be set before derived indexes are added, and it is not added again
as one of them. It is a SoilDerivedIndex too, a unique one, only its role in the collection differs.

#add: refuses an element whose primary key (or value in a unique derived index) is
taken already. It builds all keys first, so a value that cannot be indexed fails
before anything is written.

Take care: like SoilIndexedDictionary a SoilIndexedCollection has to be a root
object of the database.
"
Class {
	#name : #SoilIndexedCollection,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'primaryIndex',
		'indexes'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilIndexedCollection class >> soilTransientInstVars [
	^ #( transaction )
]

{ #category : #adding }
SoilIndexedCollection >> add: anObject [
	| primaryKey keys objectId |
	primaryIndex ifNil: [ ^ SoilUnsupportedError signal: 'the collection has no primary index' ].
	"all keys first, so that nothing is written for a value that cannot be indexed"
	primaryKey := primaryIndex keyFor: anObject primaryKey: nil.
	keys := indexes collect: [ :each | each keyFor: anObject primaryKey: primaryKey ].
	primaryIndex assertFreeKey: primaryKey of: anObject.
	indexes with: keys do: [ :each :key |
		each isUnique ifTrue: [ each assertFreeKey: key of: anObject ] ].
	objectId := transaction makeRoot: anObject.
	primaryIndex addKey: primaryKey objectId: objectId.
	indexes with: keys do: [ :each :key |
		each addKey: key objectId: objectId ].
	^ anObject
]

{ #category : #adding }
SoilIndexedCollection >> addIndex: anIndex [
	primaryIndex ifNil: [ ^ SoilUnsupportedError signal: 'set the primary index before adding derived indexes' ].
	anIndex id = primaryIndex id ifTrue: [ ^ SoilUnsupportedError signal: 'the primary index cannot also be a derived index' ].
	anIndex primaryKeySize: primaryIndex layout keySize.
	indexes add: anIndex.
	^ anIndex
]

{ #category : #accessing }
SoilIndexedCollection >> at: aValue [
	"the element whose primary attribute is aValue"
	^ self at: aValue ifAbsent: [ KeyNotFound signalFor: aValue in: self ]
]

{ #category : #accessing }
SoilIndexedCollection >> at: aValue ifAbsent: aBlock [
	^ primaryIndex at: aValue ifAbsent: aBlock
]

{ #category : #accessing }
SoilIndexedCollection >> indexFor: aSelector [
	^ ({ primaryIndex } , indexes)
		detect: [ :each | each notNil and: [ each selector = aSelector asSymbol ] ]
		ifNone: [ nil ]
]

{ #category : #accessing }
SoilIndexedCollection >> indexes [
	"the derived indexes"
	^ indexes
]

{ #category : #initialization }
SoilIndexedCollection >> initialize [
	super initialize.
	indexes := OrderedCollection new
]

{ #category : #accessing }
SoilIndexedCollection >> primary: anIndex [
	"the unique index that holds every element under its primary key"
	anIndex isUnique ifFalse: [ ^ SoilUnsupportedError signal: 'the primary index has to be unique' ].
	primaryIndex ifNotNil: [ ^ SoilUnsupportedError signal: 'the primary index is set already' ].
	primaryIndex := anIndex.
	^ anIndex
]

{ #category : #accessing }
SoilIndexedCollection >> primaryIndex [
	^ primaryIndex
]

{ #category : #removing }
SoilIndexedCollection >> remove: anObject [
	"takes anObject out of the primary and of every derived index. The keys are computed from
	the object as it is now, so a key attribute that was changed without #update: finds no entry
	and the removal is refused with a SoilKeyNotPresent. Every index is checked before any entry
	is removed, so a refused removal leaves the element in all of them. The object itself stays
	in the database, only its entries go; what happens to its record is up to the garbage collection"
	| primaryKey keys objectId entries |
	primaryIndex ifNil: [ ^ SoilUnsupportedError signal: 'the collection has no primary index' ].
	primaryKey := primaryIndex keyFor: anObject primaryKey: nil.
	keys := indexes collect: [ :each | each keyFor: anObject primaryKey: primaryKey ].
	objectId := self objectIdOf: anObject.
	entries := { primaryIndex -> primaryKey } , (indexes with: keys collect: [ :each :key | each -> key ]).
	entries do: [ :each |
		(each key holdsKey: each value objectId: objectId) ifFalse: [
			SoilKeyNotPresent new
				indexSelector: each key selector;
				key: each value;
				elementId: (anObject perform: primaryIndex selector);
				signal ] ].
	entries do: [ :each | each key removeKey: each value ].
	^ anObject
]

{ #category : #private }
SoilIndexedCollection >> committedKeyIn: anIndex of: aCopy [
	"the key anIndex held for the committed state of an element, aCopy of the object as it was
	read. The primary key it carries is the committed one"
	^ anIndex indexKey: (anIndex
		keyFor: aCopy
		primaryKey: (primaryIndex keyFor: aCopy primaryKey: nil))
]

{ #category : #private }
SoilIndexedCollection >> committedCopyOf: anObjectId [
	"a separate copy of the object as the transaction's read version holds it, made with a
	materializer of its own. Not the object of the transaction: materializing the record
	of the transaction would overwrite it"
	^ (transaction recordWithId: anObjectId)
		transaction: transaction;
		materializeObjectUsing: transaction newMaterializer
]

{ #category : #private }
SoilIndexedCollection >> journalKeyIn: anIndex of: anObjectId [
	"the key of the last entry this transaction added to anIndex for the element, or nil. A
	new element has no object id yet and every new object has the same, so it is told apart
	by the identity of its object id, the instance the entries were made with"
	^ (transaction journal entries reverse
		detect: [ :each |
			(each isKindOf: SoilAddKeyEntry) and: [
				each id = anIndex id and: [
					each value == anObjectId or: [
						anObjectId isInitialized and: [ each value = anObjectId ] ] ] ] ]
		ifNone: [ nil ])
		ifNotNil: [ :entry | entry key ]
]

{ #category : #private }
SoilIndexedCollection >> objectIdOf: anObject [
	"the object id of anObject in the transaction, nil when it is not in the database"
	^ anObject isSoilProxy
		ifTrue: [ anObject objectId ]
		ifFalse: [ transaction objectIndex at: anObject ifPresent: [ :record | record objectId ] ifAbsent: [ nil ] ]
]

{ #category : #private }
SoilIndexedCollection >> oldKeysOf: anObject objectId: anObjectId [
	"the key every index holds the element under: for each index the key of its last entry in
	the journal of the transaction, else the key from the committed version of the object. nil
	where there is none, an element that is not in the database and has no entry. A collection
	of keys per index is what several keys per element will make of it"
	| copy |
	^ ({ primaryIndex } , indexes) collect: [ :each |
		anObjectId ifNotNil: [
			(self journalKeyIn: each of: anObjectId) ifNil: [
				anObjectId isInitialized ifTrue: [
					copy ifNil: [ copy := self committedCopyOf: anObjectId ].
					self committedKeyIn: each of: copy ] ] ] ]
]

{ #category : #serializing }
SoilIndexedCollection >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction.
	transaction markDirty: self.
	primaryIndex ifNotNil: [ transaction makeRoot: primaryIndex ].
	indexes do: [ :index | transaction makeRoot: index ]
]

{ #category : #serializing }
SoilIndexedCollection >> soilLoadedIn: aTransaction [
	transaction := aTransaction
]

{ #category : #updating }
SoilIndexedCollection >> update: anObject [
	"puts every index of the element under the keys of its attributes as they are now, after one
	of them was changed. The key an index holds it under is the old one, see #oldKeysOf:objectId:.
	An index whose key did not change is not written. An index whose key did is changed with a
	removal of the old and an addition of the new key. Everything is checked before anything is
	written: every old entry has to be there and to point at the element, else a SoilKeyNotPresent,
	every new key of the primary and of a unique derived index has to be free, else a
	SoilKeyAlreadyPresent. The index core overwrites a key it moves to, so that is checked here"
	| objectId all newPrimaryKey newKeys oldKeys changed |
	primaryIndex ifNil: [ ^ SoilUnsupportedError signal: 'the collection has no primary index' ].
	objectId := self objectIdOf: anObject.
	all := { primaryIndex } , indexes.
	newPrimaryKey := primaryIndex keyFor: anObject primaryKey: nil.
	newKeys := all collect: [ :each | each keyFor: anObject primaryKey: newPrimaryKey ].
	oldKeys := self oldKeysOf: anObject objectId: objectId.
	all with: oldKeys do: [ :each :old |
		(old notNil and: [ each holdsKey: old objectId: objectId ]) ifFalse: [
			SoilKeyNotPresent new
				indexSelector: each selector;
				key: (old ifNil: [ newPrimaryKey ] ifNotNil: [ old asByteArrayOfSize: each layout keySize ]);
				elementId: (anObject perform: primaryIndex selector);
				signal ] ].
	changed := (1 to: all size) select: [ :i |
		((all at: i) indexKey: (newKeys at: i)) ~= (oldKeys at: i) ].
	changed do: [ :i |
		| each |
		each := all at: i.
		(each == primaryIndex or: [ each isUnique ]) ifTrue: [
			each assertFreeKey: (newKeys at: i) of: anObject ] ].
	changed do: [ :i |
		(all at: i) removeKey: (oldKeys at: i).
		(all at: i) addKey: (newKeys at: i) objectId: objectId ].
	^ anObject
]

{ #category : #accessing }
SoilIndexedCollection >> values [
	^ self primaryIndex values
]
