Class {
	#name : #SoilCopyOnWriteIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'wrappedStore',
		'copiedOffsets'
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

{ #category : #initialization }
SoilCopyOnWriteIndexStore >> initialize [
	super initialize.
	copiedOffsets := Set new
]

{ #category : #testing }
SoilCopyOnWriteIndexStore >> isCopyAt: anInteger [
	"whether the page at this offset is a copy of a page of the wrapped store, and not one
	that was allocated here"
	^ copiedOffsets includes: anInteger
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
	copiedOffsets add: anInteger.
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
