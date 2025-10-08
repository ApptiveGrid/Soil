"
NOTE: Deprecated ! 
Instead of using this class, create a SoilIndexedDictionary with a SoilBTree as a backend:

SoilIndexedDictionary newWithBackend: SoilBTree
"
Class {
	#name : #SoilBTreeDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-Deprecated'
}

{ #category : #testing }
SoilBTreeDictionary class >> isDeprecated [ 
	^true
]

{ #category : #initialization }
SoilBTreeDictionary >> initialize [ 
	super initialize.
	self createIndexWith: SoilBTree
]
