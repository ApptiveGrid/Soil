Class {
	#name : #SoilPagedIndexStore,
	#superclass : #Object,
	#instVars : [
		'pages',
		'index',
		'pagesMutex'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilPagedIndexStore class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilPagedIndexStore
]

{ #category : #initialization }
SoilPagedIndexStore >> allocatePage [
	^ index allocatePage 
]

{ #category : #flushing }
SoilPagedIndexStore >> flush [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPagedIndexStore >> flushCachedPages [
	pages removeAll
]

{ #category : #testing }
SoilPagedIndexStore >> hasHeaderPage [
	^ pages includesKey: 1
]

{ #category : #accessing }
SoilPagedIndexStore >> headerPage [
	^ self pageAt: 1
]

{ #category : #accessing }
SoilPagedIndexStore >> includesPageAt: anInteger [ 
	^ pages includesKey: anInteger 
]

{ #category : #accessing }
SoilPagedIndexStore >> index [
	^ index
]

{ #category : #accessing }
SoilPagedIndexStore >> index: aCollection [ 
	index := aCollection
]

{ #category : #initialization }
SoilPagedIndexStore >> initialize [ 
	super initialize.
	pages := Dictionary new.
	pagesMutex := Mutex new

]

{ #category : #testing }
SoilPagedIndexStore >> isCopyOnWrite [
	^ false
]

{ #category : #testing }
SoilPagedIndexStore >> isOpen [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPagedIndexStore >> lastPageOffset [
	^ self headerPage lastPageOffset
]

{ #category : #'instance creation' }
SoilPagedIndexStore >> newPage [
	^ index allocatePage
]

{ #category : #accessing }
SoilPagedIndexStore >> nextPageOffset [
	^ self headerPage nextPageOffset
]

{ #category : #private }
SoilPagedIndexStore >> orderedPages [
	| page orderedPages |
	page := self pageAt: 1.
	orderedPages := OrderedCollection new.
	orderedPages add: page.
	[ page isLastPage ] whileFalse: [ 
	   page := self pageAt: page next.
		orderedPages add: page
	].
	^ orderedPages
		
]

{ #category : #accessing }
SoilPagedIndexStore >> pageAt: anInteger [ 
	^ pagesMutex critical: [  
		pages 
			at: anInteger 
			ifAbsent: [ self pageFaultAt: anInteger ] ]
]

{ #category : #accessing }
SoilPagedIndexStore >> pageAt: anInteger put: aPage [ 
	^ pagesMutex critical: [  
		(pages includesKey: anInteger) 
			ifTrue: [ ^ Error signal: 'store already has page with key ', anInteger asString ].
		pages 
			at: anInteger 
			put: aPage ]
]

{ #category : #accessing }
SoilPagedIndexStore >> pageFaultAt: anInteger [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPagedIndexStore >> pages [
	^ pages
]

{ #category : #accessing }
SoilPagedIndexStore >> removePageAt: anInteger [ 
	pages removeKey: anInteger 
]
