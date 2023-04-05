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
	^ underlyingStore allItems 
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
	pages at: anInteger put: page.
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
