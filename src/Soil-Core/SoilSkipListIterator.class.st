Class {
	#name : #SoilSkipListIterator,
	#superclass : #Object,
	#instVars : [
		'maxLevel',
		'levels',
		'page'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListIterator >> at: key put: anObject [
	levels at: key put: anObject 
]

{ #category : #accessing }
SoilSkipListIterator >> levelAt: anInteger [ 
	^ levels at: anInteger 
]

{ #category : #accessing }
SoilSkipListIterator >> maxLevel: anInteger [ 
	maxLevel := anInteger.
	levels := Array new: anInteger  
]

{ #category : #accessing }
SoilSkipListIterator >> page [
	^ page
]

{ #category : #accessing }
SoilSkipListIterator >> page: aSoilSkipListPage [ 
	page := aSoilSkipListPage 
]
