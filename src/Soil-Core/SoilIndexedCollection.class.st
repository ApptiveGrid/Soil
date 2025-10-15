Class {
	#name : #SoilIndexedCollection,
	#superclass : #SoilBasicIndexedCollection,
	#instVars : [
		'indexes'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilIndexedCollection class >> soilTransientInstVars [ 
	^ #( transaction segment)
]

{ #category : #adding }
SoilIndexedCollection >> add: anObject [
	| objectId |
	objectId := transaction makeRoot: anObject.
	indexes do: [ :index | 
		index add: anObject objectId: objectId ]
]

{ #category : #'as yet unclassified' }
SoilIndexedCollection >> addIndex: anIndex [ 
	indexes add: anIndex 
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

{ #category : #'as yet unclassified' }
SoilIndexedCollection >> primaryIndex [
	^ indexes first
]

{ #category : #private }
SoilIndexedCollection >> soilClusterRootIn: aTransaction [
	transaction ifNotNil: [ ^ self ].
	transaction := aTransaction.
	transaction markDirty: self.
	indexes do: [:index | transaction makeRoot: index ]. 
	"self isRegistered ifFalse: [ 
		self halt.
		aTransaction addJournalEntry: (index newIndexEntry 
			id: id;
			segment: (aTransaction objectIdOf: self) segment) ]"
]

{ #category : #accessing }
SoilIndexedCollection >> values [
	^ self primaryIndex newIterator values 
]
