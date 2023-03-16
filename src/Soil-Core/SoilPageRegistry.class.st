Class {
	#name : #SoilPageRegistry,
	#superclass : #Object,
	#instVars : [
		'skipList',
		'headerPage',
		'stream',
		'pages'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #queries }
SoilPageRegistry >> allItems [
	^ (self readPageAt: 1) items
]

{ #category : #initialization }
SoilPageRegistry >> buildHeaderPage [
	^ SoilSkipListHeaderPage new 
		startPageIndex: 1;
		yourself.

]

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

{ #category : #accessing }
SoilPageRegistry >> flush [
	self flushPages 
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
		headerPage := self buildHeaderPage ]
]

{ #category : #initialization }
SoilPageRegistry >> initialize [ 
	super initialize.
	pages := Dictionary new.

]

{ #category : #initialization }
SoilPageRegistry >> initializeFilesystem [
	self 
		openStream;
		initializeHeaderPage;
		initializeFirstPage
]

{ #category : #initialization }
SoilPageRegistry >> initializeFirstPage [
	| page |
	page := skipList newPage
		registry: self;
		beFirstPage;
		yourself.
	pages at: page index put: page.
	self writePage: page
		
]

{ #category : #initialization }
SoilPageRegistry >> initializeHeaderPage [
	self writeHeaderPage 
]

{ #category : #accessing }
SoilPageRegistry >> lastPage [
	| maxLevel page pageNumber |
	maxLevel := skipList maxLevel.
	page := self startPage.
	[ (pageNumber := page rightAt: maxLevel) isZero ] whileFalse: [ 
		page := self pageAt: pageNumber ].
	^ page
	
]

{ #category : #accessing }
SoilPageRegistry >> maxLevel [
	^ skipList maxLevel
]

{ #category : #opening }
SoilPageRegistry >> open [
	self openStream.
	headerPage := self readHeaderPage
]

{ #category : #opening }
SoilPageRegistry >> openStream [
	stream := SOLockableStream path: skipList path.
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
	^ 4096
]

{ #category : #'instance creation' }
SoilPageRegistry >> positionOfPageIndex: anInteger [
	^ self pagesStart + ((anInteger - 1) * self filePageSize)
]

{ #category : #'as yet unclassified' }
SoilPageRegistry >> readHeaderPage [
	stream position: 0.
	^ SoilSkipListHeaderPage new readFrom: stream
]

{ #category : #accessing }
SoilPageRegistry >> readPageAt: anInteger [
	| page |
	stream position: (self positionOfPageIndex: anInteger).
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
	pagePosition := self positionOfPageIndex: aPage index.  
	stream position: pagePosition.
	aPage writeOn: stream.
	stream flush
]
