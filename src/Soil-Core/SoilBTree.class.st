Class {
	#name : #SoilBTree,
	#superclass : #SoilBasicBTree,
	#instVars : [
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
