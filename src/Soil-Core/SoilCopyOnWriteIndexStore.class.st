Class {
	#name : #SoilCopyOnWriteIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'underlyingStore'
	],
	#category : #'Soil-Core-Index-SkipList'
}

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

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> headerPage [ 
	^ underlyingStore headerPage
]

{ #category : #testing }
SoilCopyOnWriteIndexStore >> isCopyOnWrite [ 
	^ true
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> pageFaultAt: anInteger [ 
	| page |
	underlyingStore ifNotNil: [ 
		underlyingStore hasStream 
			ifTrue: [ ^ underlyingStore pageAt: anInteger ] ].
	page := self createNewPage.
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

{ #category : #'as yet unclassified' }
SoilCopyOnWriteIndexStore >> writableStore [ 
	^ underlyingStore 
]
