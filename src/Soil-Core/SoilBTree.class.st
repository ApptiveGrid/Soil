Class {
	#name : #SoilBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
		'path',
		'keySize',
		'valueSize'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'open/close' }
SoilBTree >> close [ 
	super close.
	keySize := nil
]

{ #category : #deleting }
SoilBTree >> destroy [
	path ensureDelete 
]

{ #category : #testing }
SoilBTree >> isRegistered [
	^ path notNil
]

{ #category : #accessing }
SoilBTree >> keySize [
	^ keySize ifNil: [
		keySize := super keySize ]
]

{ #category : #accessing }
SoilBTree >> keySize: anInteger [
	super keySize: anInteger.
	keySize := anInteger
]

{ #category : #accessing }
SoilBTree >> path [

	^ path
]

{ #category : #accessing }
SoilBTree >> path: aStringOrFileReference [
	(store isKindOf: SoilMemoryIndexStore) ifTrue: [ self halt ].
	store ifNil: [  
		store := self newFileStore ].

	path := aStringOrFileReference asFileReference 
]

{ #category : #converting }
SoilBTree >> thePersistentInstance [
(store isKindOf: SoilMemoryIndexStore) ifTrue: [ self halt ]. 
	^ self
]

{ #category : #accessing }
SoilBTree >> valueSize [
	^ valueSize ifNil: [ 
		valueSize := super valueSize ]
]

{ #category : #accessing }
SoilBTree >> valueSize: anInteger [ 
	super valueSize: anInteger.
	valueSize := anInteger
]
