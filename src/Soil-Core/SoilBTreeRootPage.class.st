Class {
	#name : #SoilBTreeRootPage,
	#superclass : #SoilBTreeIndexPage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #initialization }
SoilBTreeRootPage >> initialize [
	super initialize.
	self addItem: 0 -> 1 "headPage id"
]
