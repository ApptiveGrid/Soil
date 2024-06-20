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
SoilBTreeIterator >> basicAt: indexKey put: anObject [
	| possiblePriorValue |
	possiblePriorValue := index rootPage insertItem: (indexKey -> anObject) for: self.
	"as an optimization we return the prior value stored in the list. If there was none we return nil"
	^ possiblePriorValue returnValue
]

{ #category : #private }
SoilBTreeIterator >> findPageFor: indexKey [
	^currentPage := index rootPage find: indexKey with: index
]

{ #category : #private }
SoilBTreeIterator >> findPreviousPageOf: aPage [
	
	aPage isHeaderPage ifTrue: [ ^nil ].
	aPage isEmpty ifTrue: [ ^super findPreviousPageOf: aPage ].
	"The previous page can be found by searching using the index pages for the first item in aPage"
	^currentPage := index rootPage findPreviousPage: aPage firstItem key with: index
]

{ #category : #accessing }
SoilBTreeIterator >> lastPage [
	"follow the last index entry till reaching a data page"
	currentPage := index rootPage.
	[ currentPage isIndexPage ] whileTrue: [
		 currentPage := self pageAt: currentPage lastItem value ].
	^ currentPage
]
