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
	^ (pages flatCollect: [ :page | page items ]) allButLast allButFirst
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

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeFilesystem [
	self openStream
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeHeaderPage [
	| page |
	page := index newHeaderPage.
	pages at: page index put: page		
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
