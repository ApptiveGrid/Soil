"
A SoilIndexedCollection is a collection of objects that is reachable through
several indexes at once. Every SoilObjectIndex added with #addIndex: derives its
own key from the objects that are added, so the same object can be looked up by
different properties.

Take care: like SoilIndexedDictionary a SoilIndexedCollection has to be a root
object of the database.
"
Class {
	#name : #SoilIndexedCollection,
	#superclass : #Object,
	#instVars : [
		'transaction',
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
	| objectId |
	objectId := transaction makeRoot: anObject.
	indexes do: [ :index |
		index add: anObject objectId: objectId ].
	^ anObject
]

{ #category : #adding }
SoilIndexedCollection >> addIndex: anIndex [
	indexes add: anIndex.
	^ anIndex
]

{ #category : #accessing }
SoilIndexedCollection >> indexes [
	^ indexes
]

{ #category : #initialization }
SoilIndexedCollection >> initialize [
	super initialize.
	indexes := OrderedCollection new
]

{ #category : #accessing }
SoilIndexedCollection >> indexFor: aSelector [
	^ indexes
		detect: [ :each | each selector = aSelector asSymbol ]
		ifNone: [ nil ]
]

{ #category : #accessing }
SoilIndexedCollection >> primaryIndex [
	^ indexes first
]

{ #category : #serializing }
SoilIndexedCollection >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction.
	transaction markDirty: self.
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
