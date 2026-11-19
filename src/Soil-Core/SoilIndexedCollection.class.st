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

{ #category : #accessing }
SoilIndexedCollection >> values [
	^ self primaryIndex values
]
