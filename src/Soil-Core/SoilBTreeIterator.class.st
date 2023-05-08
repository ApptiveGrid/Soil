Class {
	#name : #SoilBTreeIterator,
	#superclass : #SoilIndexIterator,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'instance creation' }
SoilBTreeIterator class >> on: aSoilBtree [
	^ self new 
		index: aSoilBtree 
]

{ #category : #private }
SoilBTreeIterator >> find: key [
	currentKey := key.
	currentPage := index rootPage find: key with: index.
	^ currentPage valueAt: currentKey
]

{ #category : #accessing }
SoilBTreeIterator >> lastPage [
	| pageNumber |
	currentPage := index headerPage.
	[ (pageNumber := currentPage next) isZero ] whileFalse: [ 
		currentPage := self pageAt: pageNumber ].
	^currentPage
]

{ #category : #accessing }
SoilBTreeIterator >> nextAssociation [
	| item |
	nextKey ifNotNil: [ 
		item := currentPage 
			itemAt: nextKey 
			ifAbsent: [ Error signal: 'shoulndt be possible' ].
		nextKey := nil.
		^ item ].
	currentPage ifNil: [ 
		currentPage := index headerPage.
		currentKey := nil ].
	[ currentPage isNil ] whileFalse: [  
		item := currentKey 
			ifNotNil: [  
				(currentPage itemAfter: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						(currentPage next == 0) ifTrue: [ ^ nil ].
						currentPage := self pageAt: currentPage next.
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage firstItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]
