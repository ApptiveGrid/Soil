Class {
	#name : #SoilBTreeRootPage,
	#superclass : #SoilBTreeIndexPage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'as yet unclassified' }
SoilBTreeRootPage class >> pageCode [ 
	^ 6
]

{ #category : #initialization }
SoilBTreeRootPage >> initialize [
	super initialize.
	self addItem: 0 -> (1 asByteArrayOfSize: 2) "headPage id"
]
