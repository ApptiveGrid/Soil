"
This class implements the SoilIndexDictionary that uses a B+Tree.

See the superclass for more informaion about indexed dictionaries
"
Class {
	#name : #SoilBTreeDictionary,
	#superclass : #SoilIndexedDictionary,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #initialization }
SoilBTreeDictionary >> initialize [ 
	super initialize.
	self createIndexWith: SoilBTree
]
