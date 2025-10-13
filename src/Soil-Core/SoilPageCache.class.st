Class {
	#name : #SoilPageCache,
	#superclass : #Object,
	#instVars : [
		'pages',
		'index',
		'pagesMutex'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilPageCache class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilPageCache
]

{ #category : #initialization }
SoilPageCache >> allocatePage [
	^ index allocatePage 
]

{ #category : #flushing }
SoilPageCache >> flush [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPageCache >> flushCachedPages [
	pages removeAll
]

{ #category : #testing }
SoilPageCache >> hasHeaderPage [
	^ pages includesKey: 1
]

{ #category : #accessing }
SoilPageCache >> headerPage [
	^ self pageAt: 1
]

{ #category : #accessing }
SoilPageCache >> includesPageAt: anInteger [ 
	^ pages includesKey: anInteger 
]

{ #category : #accessing }
SoilPageCache >> index [
	^ index
]

{ #category : #accessing }
SoilPageCache >> index: aCollection [ 
	index := aCollection
]

{ #category : #initialization }
SoilPageCache >> initialize [ 
	super initialize.
	pages := Dictionary new.
	pagesMutex := Mutex new

]

{ #category : #testing }
SoilPageCache >> isCopyOnWrite [
	^ false
]

{ #category : #testing }
SoilPageCache >> isOpen [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPageCache >> lastPageOffset [
	^ self headerPage lastPageOffset
]

{ #category : #'instance creation' }
SoilPageCache >> newPage [
	^ index allocatePage
]

{ #category : #accessing }
SoilPageCache >> nextPageOffset [
	^ self headerPage nextPageOffset
]

{ #category : #private }
SoilPageCache >> orderedPages [
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
SoilPageCache >> pageAt: anInteger [ 
	^ pagesMutex critical: [  
		pages 
			at: anInteger 
			ifAbsent: [ self pageFaultAt: anInteger ] ]
]

{ #category : #accessing }
SoilPageCache >> pageAt: anInteger put: aPage [ 
	^ pagesMutex critical: [  
		(pages includesKey: anInteger) 
			ifTrue: [ ^ Error signal: 'store already has page with key ', anInteger asString ].
		pages 
			at: anInteger 
			put: aPage ]
]

{ #category : #accessing }
SoilPageCache >> pageFaultAt: anInteger [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilPageCache >> pages [
	^ pages
]

{ #category : #accessing }
SoilPageCache >> removePageAt: anInteger [ 
	pages removeKey: anInteger 
]
