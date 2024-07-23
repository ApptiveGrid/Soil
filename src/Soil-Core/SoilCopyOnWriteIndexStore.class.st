Class {
	#name : #SoilCopyOnWriteIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'wrappedStore'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #flushing }
SoilCopyOnWriteIndexStore >> flush [ 
	^ wrappedStore flush
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> flushCachedPages [ 
	super flushCachedPages.
	wrappedStore flushCachedPages 
]

{ #category : #testing }
SoilCopyOnWriteIndexStore >> isCopyOnWrite [ 
	^ true
]

{ #category : #testing }
SoilCopyOnWriteIndexStore >> isOpen [ 
	^ wrappedStore isOpen
]

{ #category : #accessing }
SoilCopyOnWriteIndexStore >> pageFaultAt: anInteger [ 
	| page |
	page := (wrappedStore pageAt: anInteger) copy.
	pages at: anInteger put: page.
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
