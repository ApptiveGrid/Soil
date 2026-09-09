"
The SoilBTreeIterator implements the SoilIndexIterator for the B+Tree index.


To get an iterator, call #newIterator on the index when used stand-alone, if the index is used for a SoilIndexedDictionary,
use the #newIterator there to setup the iterator correctly.
"
Class {
	#name : #SoilBTreeIterator,
	#superclass : #SoilRestoringIndexIterator,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeIterator >> basicAt: indexKey add: anObject [
	| possiblePriorValue |	
	possiblePriorValue := index rootPage insertItem: (indexKey -> anObject) for: self.
	^ possiblePriorValue returnValue
]

{ #category : #accessing }
SoilBTreeIterator >> basicAt: indexKey put: anObject [
	<ignoreForCoverage>
	self
		deprecated: 'Please use #basicAt:add:'
		transformWith: '`@receiver basicAt: `@arg1 put: `@arg2' -> '`@receiver basicAt: `@arg1 add: `@arg2'.

	^ self basicAt: indexKey add: anObject 
]

{ #category : #private }
SoilBTreeIterator >> findPageFor: indexKey [
	^currentPage := index rootPage find: indexKey with: index
]

{ #category : #private }
SoilBTreeIterator >> findPageFor: indexKey value: anObject [
	^currentPage := index rootPage findItem: indexKey->anObject with: index
]

{ #category : #accessing }
SoilBTreeIterator >> lastPage [
	"follow the last index entry till reaching a data page"
	currentPage := index rootPage.
	[ currentPage isIndexPage ] whileTrue: [
		 currentPage := self pageAt: currentPage lastItem value ].
	^ currentPage
]
