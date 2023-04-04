Class {
	#name : #SoilPagedFileIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'stream'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #queries }
SoilPagedFileIndexStore >> allItems [
self halt.
	^ (self pageFaultAt: 1) items
]

{ #category : #converting }
SoilPagedFileIndexStore >> asCopyOnWriteStore [
	^ SoilCopyOnWriteIndexStore new 
		underlyingStore: self
]

{ #category : #'initialize-release' }
SoilPagedFileIndexStore >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> filePageSize [
	"most OSses use a file page size of 4k today"
	^ 4096
]

{ #category : #accessing }
SoilPagedFileIndexStore >> flush [
	self flushPages 
]

{ #category : #'as yet unclassified' }
SoilPagedFileIndexStore >> flushPages [
	pages valuesDo: [ :page |
		page isDirty ifTrue: [ 
			self writePage: page ] ]
]

{ #category : #testing }
SoilPagedFileIndexStore >> hasStream [
	^ stream notNil
]

{ #category : #accessing }
SoilPagedFileIndexStore >> index: anIndex [ 
	super index: anIndex.
	pages ifEmpty: [ self initializeHeaderPage ]
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeFilesystem [
	self openStream
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeHeaderPage [
	| page |
	page := index newHeaderPage.
	pages at: page index put: page.
	"self writePage: page"
		
]

{ #category : #accessing }
SoilPagedFileIndexStore >> lastPage [
	| maxLevel page pageNumber |
	self halt.
	maxLevel := index maxLevel.
	page := self headerPage.
	[ (pageNumber := page rightAt: maxLevel) isZero ] whileFalse: [ 
		page := self pageAt: pageNumber ].
	^ page
	
]

{ #category : #accessing }
SoilPagedFileIndexStore >> maxLevel [
self halt.
	^ index maxLevel
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> open [
	self 
		openStream;
		readHeaderPage 
]

{ #category : #opening }
SoilPagedFileIndexStore >> openStream [
	stream := SOLockableStream path: index path.
]

{ #category : #accessing }
SoilPagedFileIndexStore >> pageFaultAt: anInteger [
	| page |
	stream position: (self positionOfPageIndex: anInteger).
	page := index newPage 
		registry: self;
		readFrom: stream.
	"(pages size > anInteger) ifFalse: [ 
		 pages := pages grownBy: (anInteger - pages size)]."
	pages at: anInteger put: page.
	^ page
]

{ #category : #'as yet unclassified' }
SoilPagedFileIndexStore >> pagesStart [
	^ 4096
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> positionOfPageIndex: anInteger [
	^ ((anInteger - 1) * self filePageSize)
]

{ #category : #'as yet unclassified' }
SoilPagedFileIndexStore >> readHeaderPage [
	stream position: 0.
	pages at: 1 put: (index newHeaderPage readFrom: stream)
]

{ #category : #accessing }
SoilPagedFileIndexStore >> replace: oldPage with: newPage [ 
	pages
		at: oldPage index 
		put:newPage 
]

{ #category : #'as yet unclassified' }
SoilPagedFileIndexStore >> splitPage: aIterator [ 
	| newPage page |
	self halt.
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

{ #category : #accessing }
SoilPagedFileIndexStore >> stream [
	^ stream 
]

{ #category : #writing }
SoilPagedFileIndexStore >> writeHeaderPage [
	self stream position: 0.
	self headerPage writeOn: self stream
]

{ #category : #writing }
SoilPagedFileIndexStore >> writePage: aPage [ 
	| pagePosition |
	pagePosition := self positionOfPageIndex: aPage index.  
	stream position: pagePosition.
	aPage writeOn: stream.
	stream flush
]
