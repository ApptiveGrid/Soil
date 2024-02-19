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

{ #category : #'instance creation' }
SoilBTree >> newPage [
	^ self pageClass new 
		keySize: self keySize;
		valueSize: self valueSize;
		pageSize: self pageSize;
		yourself
]

{ #category : #reindexing }
SoilBTree >> newPluggableRewriter [
	^ SoilPluggableReindexer new 
		index: self
]

{ #category : #accessing }
SoilBTree >> path [

	^ path
]

{ #category : #accessing }
SoilBTree >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #reindexing }
SoilBTree >> rewrite [
	self newPluggableRewriter run
]

{ #category : #converting }
SoilBTree >> thePersistentInstance [
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
