Class {
	#name : #SoilWritableSkipListPage,
	#superclass : #SoilSkipListPage,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #converting }
SoilWritableSkipListPage >> asModifiable [ 
	^ self
]
