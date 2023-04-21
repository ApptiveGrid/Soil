Class {
	#name : #SoilCopyOnWriteIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'wrappedStore'
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
	^ wrappedStore flush
]

{ #category : #testing }
SoilCopyOnWriteIndexStore >> isCopyOnWrite [ 
	^ true
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> pageFaultAt: anInteger [ 
	| page |
	page := wrappedStore 
		ifNotNil: [ wrappedStore pageAt: anInteger ]
		ifNil: [ self createNewPage ].
	pages at: anInteger put: page copy.
	^ page 
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> wrappedStore [

	^ wrappedStore
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> wrappedStore: anObject [

	wrappedStore := anObject
]
