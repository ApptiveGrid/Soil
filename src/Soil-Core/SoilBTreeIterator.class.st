Class {
	#name : #SoilBTreeIterator,
	#superclass : #SoilIndexIterator,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeIterator >> at: aKeyObject ifAbsent: aBlock [
	currentKey := (aKeyObject asSkipListKeyOfSize: index keySize) asInteger.
	^ self find: currentKey ifAbsent: aBlock
]

{ #category : #accessing }
SoilBTreeIterator >> at: aKeyObject put: anObject [
	| key |
	key := (aKeyObject asSkipListKeyOfSize: index keySize) asInteger.
	^ self 
		basicAt: key 
		put: anObject
]

{ #category : #accessing }
SoilBTreeIterator >> basicAt: key put: anObject [
	index rootPage insert: key -> anObject into: self.
	^anObject
]

{ #category : #private }
SoilBTreeIterator >> find: key [
	currentKey := key.
	currentPage := index rootPage find: key with: index.
	^ currentPage valueAt: currentKey
]

{ #category : #private }
SoilBTreeIterator >> find: key ifAbsent: aBlock [
	currentKey := key.
	currentPage := index rootPage find: key with: index.
	^ currentPage valueAt: currentKey ifAbsent: aBlock
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
