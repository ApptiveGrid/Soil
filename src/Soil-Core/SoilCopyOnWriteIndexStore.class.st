Class {
	#name : #SoilCopyOnWriteIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'underlyingStore'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #queries }
SoilCopyOnWriteIndexStore >> allItems [
	| highestIndex col |
	highestIndex := self lastPageIndex.
	col := OrderedCollection new.
	1 to: highestIndex do: [ :n |
		col addAll: (self pageAt: n) items ].
	^ (col reject: [ :each | 
			(each value class = SmallInteger) and: [ each value asInteger = 0 ] ]) collect: #value
]

{ #category : #'as yet unclassified' }
SoilCopyOnWriteIndexStore >> createNewPage [
	^ index newWritablePage 
		index: self nextIndex;
		registry: self
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> flush [ 
	^ underlyingStore flush
]

{ #category : #testing }
SoilCopyOnWriteIndexStore >> isCopyOnWrite [ 
	^ true
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> pageFaultAt: anInteger [ 
	| page |
	page := underlyingStore 
		ifNotNil: [ underlyingStore pageAt: anInteger ]
		ifNil: [ self createNewPage ].
	pages at: anInteger put: page copy.
	^ page 
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> underlyingStore [

	^ underlyingStore
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> underlyingStore: anObject [

	underlyingStore := anObject
]
