Class {
	#name : #SoilCopyOnWriteIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'wrappedStore'
	],
	#category : #'Soil-Core-Index-SkipList'
}

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
	page := wrappedStore pageAt: anInteger.
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
