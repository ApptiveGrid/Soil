Class {
	#name : #SoilCopyOnWritePageCache,
	#superclass : #SoilPageCache,
	#instVars : [
		'wrappedStore'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #flushing }
SoilCopyOnWritePageCache >> flush [ 
	^ wrappedStore flush
]

{ #category : #accessing }
SoilCopyOnWritePageCache >> flushCachedPages [ 
	super flushCachedPages.
	wrappedStore flushCachedPages 
]

{ #category : #testing }
SoilCopyOnWritePageCache >> isCopyOnWrite [ 
	^ true
]

{ #category : #testing }
SoilCopyOnWritePageCache >> isOpen [ 
	^ wrappedStore isOpen
]

{ #category : #accessing }
SoilCopyOnWritePageCache >> pageFaultAt: anInteger [ 
	| page |
	page := (wrappedStore pageAt: anInteger) copy.
	pages at: anInteger put: page.
	^ page 
]

{ #category : #accessing }
SoilCopyOnWritePageCache >> wrappedStore [

	^ wrappedStore
]

{ #category : #accessing }
SoilCopyOnWritePageCache >> wrappedStore: anObject [

	wrappedStore := anObject
]
