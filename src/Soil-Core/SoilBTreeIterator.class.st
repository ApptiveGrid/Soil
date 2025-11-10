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
	"as an optimization we return the prior value stored in the list. If there was none we return nil"
	index hasUniqueKeys 
		"only increase size if there was no prior value"
		ifTrue: [ possiblePriorValue returnValue ifNil: [index increaseSize]]
		"always for duplicate keys"
		ifFalse: [ index increaseSize ].
	
	index addDirtyPage: currentPage.
	^ possiblePriorValue returnValue
]

{ #category : #accessing }
SoilBTreeIterator >> basicAt: indexKey put: anObject [
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
SoilBTreeIterator >> findPreviousPageOf: aPage [
	| page |
	"Slow version, only used for old page format without previous pointer"
	aPage isHeaderPage ifTrue: [ ^nil ].
	page := index rootPage findPreviousPage: aPage firstItem key with: index path: OrderedCollection new.
	"for now use assert to make sure this is correct"
	self assert: (self pageAt: page next) == aPage.
	^currentPage := page
]

{ #category : #accessing }
SoilBTreeIterator >> lastPage [
	"follow the last index entry till reaching a data page"
	currentPage := index rootPage.
	[ currentPage isIndexPage ] whileTrue: [
		 currentPage := self pageAt: currentPage lastItem value ].
	^ currentPage
]

{ #category : #accessing }
SoilBTreeIterator >> size [ 
	| headerPage |
	"size in the header page is only correct if the current transaction
	read version is bigger than the last modification of the page. If 
	the header page is newer than the current transaction we need to scan
	the index for the size"
	headerPage := index headerPage.
	^ (readVersion isNil or: [ headerPage lastTransaction > readVersion ]) 
		ifTrue: [ super size] 
		ifFalse: [ index size  ]
]
