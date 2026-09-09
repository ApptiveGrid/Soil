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

{ #category : #visiting }
SoilSkipListDictionary >> acceptSoil: aSoilVisitor [
	<ignoreForCoverage> "class deprecated"
	aSoilVisitor visitSkipListDictionary: self 
]

{ #category : #initialization }
SoilSkipListDictionary >> initialize [
	<ignoreForCoverage> "class deprecated"
	super initialize.
	self createIndexWith: SoilSkipList
]
