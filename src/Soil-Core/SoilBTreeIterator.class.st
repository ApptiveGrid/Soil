Class {
	#name : #SoilBTreeIterator,
	#superclass : #SoilIndexIterator,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeIterator >> basicAt: key put: anObject [
	| posiblePrioValue |
	posiblePrioValue := index rootPage insertItem: (key -> anObject) for: self.
	"as an optimization we return the prior value stored in the list. If there was none we return nil"
	^ posiblePrioValue returnValue
]

{ #category : #private }
SoilBTreeIterator >> findPageFor: key [
	^currentPage := index rootPage find: key with: index
]

{ #category : #accessing }
SoilBTreeIterator >> index [
	^index
]

{ #category : #accessing }
SoilBTreeIterator >> lastPage [
	| pageNumber |
	currentPage := index headerPage.
	[ (pageNumber := currentPage next) isZero ] whileFalse: [ 
		currentPage := self pageAt: pageNumber ].
	^currentPage
]
