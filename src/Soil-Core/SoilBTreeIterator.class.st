Class {
	#name : #SoilBTreeIterator,
	#superclass : #Object,
	#instVars : [
		'btree',
		'currentPage',
		'currentKey',
		'nextKey'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'instance creation' }
SoilBTreeIterator class >> on: aSoilBtree [
	^ self new 
		btree: aSoilBtree 
]

{ #category : #accessing }
SoilBTreeIterator >> btree: aBtree [
	btree := aBtree
]

{ #category : #enumerating }
SoilBTreeIterator >> do: aBlock [
	| item |
	[ (item := self next) isNil ] whileFalse: [ 
		aBlock value: item ]
]

{ #category : #private }
SoilBTreeIterator >> find: key [
	currentKey := key.
	^btree rootPage find: key with: btree
]

{ #category : #accessing }
SoilBTreeIterator >> next [
	^ self nextAssociation ifNotNil: [ :assoc | assoc value ]
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
		currentPage := btree store headerPage.
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
						currentPage := btree store pageAt: (currentPage next).
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage firstItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #accessing }
SoilBTreeIterator >> page [

	^ currentPage
]
