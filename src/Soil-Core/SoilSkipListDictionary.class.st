"
NOTE: Deprecated ! 
Instead of using this class, create a SoilIndexedDictionary with a SoilSkipList as a backend:

SoilIndexedDictionary newWithBackend: SoilSkipList
"
Class {
	#name : #SoilSkipListDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-Deprecated'
}

{ #category : #initialization }
SoilSkipListDictionary >> initialize [ 
	super initialize.
	self createIndexWith: SoilSkipList
]
