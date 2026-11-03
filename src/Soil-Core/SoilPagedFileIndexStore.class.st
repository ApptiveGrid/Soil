Class {
	#name : #SoilPagedFileIndexStore,
	#superclass : #SoilPagedIndexStore,
	#instVars : [
		'stream',
		'streamSemaphore'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #visiting }
SoilPagedFileIndexStore >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitPagedFileIndexStore: self
]

{ #category : #converting }
SoilPagedFileIndexStore >> asCopyOnWriteStore [
	^ SoilCopyOnWriteIndexStore new 
		wrappedStore: self
]

{ #category : #'open/close' }
SoilPagedFileIndexStore >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> ensureStreamIsOpen [
	stream ifNotNil: [ ^ self ].
	self open
		
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> filePageSize [
	"most OSses use a file page size of 4k today"
	^ 4096
]

{ #category : #flushing }
SoilPagedFileIndexStore >> flush [
	self flushPages 
]

{ #category : #flushing }
SoilPagedFileIndexStore >> flushPages [
	pagesMutex critical: [  
		pages valuesDo: [ :page |
			page needsWrite ifTrue: [ 
				self writePage: page ] ] ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> headerPage [
	"read directly whenever it is missing, not only from an empty cache. As a page
	fault it would ask the index for its version (#readPageAt:), which is this
	header again"
	self hasHeaderPage ifFalse: [
		self ensureStreamIsOpen.
		self readHeaderPage ].
	^ super headerPage
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initialize [ 
	super initialize.
	"reentrant, because reading a page can read the header, see #readHeaderPage"
	streamSemaphore := Mutex new
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeFilesystem [
	self openStream
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initializeHeaderPage [
	| page |
	page := index newHeaderPage.
	pagesMutex critical: [  
		pages at: page offset put: page	]
]

{ #category : #testing }
SoilPagedFileIndexStore >> isOpen [
	^stream isNotNil and: [ stream isOpen ]
]

{ #category : #'open/close' }
SoilPagedFileIndexStore >> open [
	self isOpen ifTrue: [ self error: 'Index store already open' ].
	self openStream
]

{ #category : #'open/close' }
SoilPagedFileIndexStore >> openStream [
	"an index in a segment gets its stream where every file of the database gets it,
	so a read-only database opens its index files non-writable. An index used stand
	alone has no segment and opens its file read-write as before"
	streamSemaphore critical: [  
		stream := index segment
			ifNil: [ SoilLockableStream path: index path ]
			ifNotNil: [ :seg | seg soil streamOnPath: index path ] ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> pageFaultAt: anInteger [
	| page |
	self ensureStreamIsOpen.
	page := self readPageAt: anInteger.
	"when there are transactions blocking clean up, those pages
	get written with the removed items. When the page is read from
	disk we can determine if it should undergo maintenance. This can
	also be done while reading. Cleanup will happen on commit"
	page needsCleanup ifTrue: [ index addDirtyPage: page ].
	pagesMutex critical: [  
		pages at: anInteger put: page ].
	^ page
]

{ #category : #'instance creation' }
SoilPagedFileIndexStore >> positionOfPageIndex: anInteger [
	^ ((anInteger - 1) * self filePageSize)
]

{ #category : #writing }
SoilPagedFileIndexStore >> readHeaderPage [
	"the stream is shared by every process reading this index, so the header is read
	under the stream lock like any other page. The same process can already hold it:
	reading a page asks the index for its version, which is in the header, between
	reading the page code and the rest of the page. So the stream is left where it was
	found. A header another process has put in the meantime stays, it may be changed
	already"
	| headerPage |
	headerPage := streamSemaphore critical: [ | position |
		position := stream position.
		[
			stream position: 0.
			stream next. "pageCode"
			index newHeaderPage readFrom: stream ]
				ensure: [ stream position: position ] ].
	pagesMutex critical: [
		pages at: 1 ifAbsentPut: [ headerPage ] ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> readPageAt: anInteger [

	^ streamSemaphore critical: [  
		stream position: (self positionOfPageIndex: anInteger).
		(index readPageFrom: stream) 
			offset: anInteger;
			version: index version;
			pageSize:  self filePageSize
			yourself ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> removePageAt: anIndex [ 
	^ pagesMutex critical: [  
		pages removeKey: anIndex ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> replace: oldPage with: newPage [ 
	pagesMutex critical: [  
		pages
			at: oldPage offset 
			put:newPage ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> stream [
	^ stream 
]

{ #category : #writing }
SoilPagedFileIndexStore >> writeContentsToDisk [
	stream ifNotNil: [  
		stream fileStream fsync ]
]

{ #category : #writing }
SoilPagedFileIndexStore >> writePage: aPage [ 
	| pagePosition |
	self ensureStreamIsOpen.
	streamSemaphore critical: [  
		pagePosition := self positionOfPageIndex: aPage offset.  
		stream position: pagePosition.
		aPage writeOn: stream.
		stream flush ]
]
