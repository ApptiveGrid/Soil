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

{ #category : #visiting }
SoilBTreeDictionary >> acceptSoil: aSoilVisitor [
	"the other half of the dispatch SoilSkipListDictionary has had. Without it any visitor
	meeting one of these dies with a doesNotUnderstand, which says nothing about what it
	met - see SoilGraphExporter>>visitBTreeDictionary: for a visitor that cannot carry one
	and now says so."
	^ aSoilVisitor visitBTreeDictionary: self
]

{ #category : #initialization }
SoilBTreeDictionary >> initialize [ 
	<ignoreForCoverage> "class deprecated"
	super initialize.
	self createIndexWith: SoilBTree
]
