Class {
	#name : #SoilPageRegistry,
	#superclass : #Object,
	#instVars : [
		'skipList',
		'headerPage',
		'stream',
		'pages',
		'random'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'initialize-release' }
SoilPageRegistry >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
]

{ #category : #'instance creation' }
SoilPageRegistry >> filePageSize [
	"most OSses use a file page size of 4k today"
	^ 4096
]

{ #category : #'as yet unclassified' }
SoilPageRegistry >> flushPages [
	pages valuesDo: [ :page |
		page isDirty ifTrue: [ 
			self writePage: page ] ]
]

{ #category : #'as yet unclassified' }
SoilPageRegistry >> headerPage [
	^ headerPage ifNil: [ 
		headerPage := self readHeaderPage ]
]

{ #category : #initialization }
SoilPageRegistry >> initialize [ 
	super initialize.
	pages := Dictionary new.
	random := Random seed: Time millisecondClockValue 
]

{ #category : #initialization }
SoilPageRegistry >> initializeFirstPage [
	| page |
	page := skipList newPage
		registry: self;
		level: skipList maxLevel;
		beFirstPage;
		yourself.
	pages at: page index put: page.
	self writePage: page
		
]

{ #category : #initialization }
SoilPageRegistry >> initializeHeaderPage [
	headerPage := SoilSkipListHeaderPage new 
		startPageIndex: 1;
		yourself.
	self writeHeaderPage 
]

{ #category : #accessing }
SoilPageRegistry >> maxLevel [
	^ skipList maxLevel
]

{ #category : #accessing }
SoilPageRegistry >> nextPageIndex [
	^ pages size + 1
]

{ #category : #opening }
SoilPageRegistry >> open [
	stream := SOLockableStream path: skipList path
]

{ #category : #accessing }
SoilPageRegistry >> pageAt: anInteger [ 
	^ pages 
		at: anInteger 
		ifAbsentPut: [ self readPageAt: anInteger ]
]

{ #category : #accessing }
SoilPageRegistry >> pages [
	^ pages
]

{ #category : #'as yet unclassified' }
SoilPageRegistry >> pagesStart [
	^ 10
]

{ #category : #'instance creation' }
SoilPageRegistry >> positionOfPage: aPage [ 
	^ self pagesStart + ((aPage index - 1) * self filePageSize)
]

{ #category : #accessing }
SoilPageRegistry >> random [

	^ random
]

{ #category : #accessing }
SoilPageRegistry >> readPageAt: anInteger [
	| page |
	stream position: (self pagesStart + ((anInteger - 1) * self filePageSize)).
	page := skipList newPage 
		registry: self;
		readFrom: stream.
	"(pages size > anInteger) ifFalse: [ 
		 pages := pages grownBy: (anInteger - pages size)]."
	pages at: anInteger put: page.
	^ page
]

{ #category : #accessing }
SoilPageRegistry >> skipList [
	^ skipList
]

{ #category : #accessing }
SoilPageRegistry >> skipList: aSoilSkipList [ 
	skipList := aSoilSkipList 
]

{ #category : #'as yet unclassified' }
SoilPageRegistry >> splitPage: aIterator [ 
	| newPage page |
	page := aIterator page.
	newPage := page split.
	newPage index: pages size + 1.
	newPage initializeLevel.
	newPage level to: 1 by: -1  do: [ :level |
		(level > page level)
			ifTrue: [ 
				newPage rightAt: level put: ((aIterator levelAt: level) rightAt: level).
				(aIterator levelAt: level) rightAt: level put: newPage index ]
			ifFalse: [ 
				(page rightAt: level) ifNotNil: [ :r | 
					newPage rightAt: level put: r ].
				page rightAt: level put: newPage index ]].
	pages at: newPage index put: newPage.
	^ newPage 
]

{ #category : #'as yet unclassified' }
SoilPageRegistry >> startPage [
	^ self pageAt: self headerPage startPageIndex
]

{ #category : #accessing }
SoilPageRegistry >> stream [
	^ stream 
]

{ #category : #writing }
SoilPageRegistry >> writeHeaderPage [
	self stream position: 0.
	self headerPage writeOn: self stream
]

{ #category : #writing }
SoilPageRegistry >> writePage: aPage [ 
	| pagePosition |
	pagePosition := self positionOfPage: aPage.  
	stream position: pagePosition.
	aPage writeOn: stream
]
