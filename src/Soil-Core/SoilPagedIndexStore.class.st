Class {
	#name : #SoilPagedIndexStore,
	#superclass : #Object,
	#instVars : [
		'pages',
		'index'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'as yet unclassified' }
SoilPagedIndexStore >> headerPage [
	^ self pageAt: 1
]

{ #category : #accessing }
SoilPagedIndexStore >> highestPageIndex [ 
	^ pages size
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

]

{ #category : #testing }
SoilPagedIndexStore >> isCopyOnWrite [
	^ false
]

{ #category : #accessing }
SoilPagedIndexStore >> nextIndex [
	^ pages size + 1
]

{ #category : #accessing }
SoilPagedIndexStore >> pageAt: anInteger [ 
	^ pages 
		at: anInteger 
		ifAbsent: [ self pageFaultAt: anInteger]
]

{ #category : #accessing }
SoilPagedIndexStore >> pageAt: anInteger put: aPage [ 
	pages 
		at: anInteger 
		put: aPage
]

{ #category : #accessing }
SoilPagedIndexStore >> pageFaultAt: anInteger [ 
	| page |
	page := index pageAt: anInteger.
]

{ #category : #accessing }
SoilPagedIndexStore >> pages [
	^ pages
]

{ #category : #'as yet unclassified' }
SoilPagedIndexStore >> writableStore [
	^ self 
]
