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
			page isDirty ifTrue: [ 
				self writePage: page ] ] ]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> headerPage [ 
	pages ifEmpty: [ 
		self ensureStreamIsOpen.
		self readHeaderPage ].
	^ super headerPage
]

{ #category : #initialization }
SoilPagedFileIndexStore >> initialize [ 
	super initialize.
	streamSemaphore := Semaphore forMutualExclusion 
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
	streamSemaphore critical: [  
		stream := SoilLockableStream path: index path
	]
]

{ #category : #accessing }
SoilPagedFileIndexStore >> pageFaultAt: anInteger [
	| page |
	self ensureStreamIsOpen.
	streamSemaphore critical: [  
		stream position: (self positionOfPageIndex: anInteger).
		page := (index readPageFrom: stream) 
			offset: anInteger;
			pageSize:  self filePageSize
			yourself ].
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
	| headerPage |
	stream position: 0.
	stream next. "pageCode"
	headerPage :=  index newHeaderPage readFrom: stream.
	pagesMutex critical: [  
		pages at: 1 put: headerPage ]
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
