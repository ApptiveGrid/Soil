Class {
	#name : #SoilFilePageCache,
	#superclass : #SoilPageCache,
	#instVars : [
		'stream',
		'streamSemaphore',
		'path'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #visiting }
SoilFilePageCache >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitPagedFileIndexStore: self
]

{ #category : #converting }
SoilFilePageCache >> asCopyOnWriteStore [
	^ SoilCopyOnWritePageCache new 
		wrappedStore: self
]

{ #category : #'open/close' }
SoilFilePageCache >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
]

{ #category : #deleting }
SoilFilePageCache >> destroy [
	path ensureDelete 
]

{ #category : #accessing }
SoilFilePageCache >> ensureStreamIsOpen [
	stream ifNotNil: [ ^ self ].
	self open
		
]

{ #category : #'instance creation' }
SoilFilePageCache >> filePageSize [
	"most OSses use a file page size of 4k today"
	^ 4096
]

{ #category : #flushing }
SoilFilePageCache >> flush [
	self flushPages 
]

{ #category : #flushing }
SoilFilePageCache >> flushPages [
	pagesMutex critical: [  
		pages valuesDo: [ :page |
			page needsWrite ifTrue: [ 
				self writePage: page ] ] ]
]

{ #category : #accessing }
SoilFilePageCache >> headerPage [ 
	pages ifEmpty: [ 
		self ensureStreamIsOpen.
		self readHeaderPage ].
	^ super headerPage
]

{ #category : #initialization }
SoilFilePageCache >> initialize [ 
	super initialize.
	streamSemaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilFilePageCache >> initializeFilesystem [
	self openStream
]

{ #category : #initialization }
SoilFilePageCache >> initializeHeaderPage [
	| page |
	page := index newHeaderPage.
	pagesMutex critical: [  
		pages at: page offset put: page	]
]

{ #category : #testing }
SoilFilePageCache >> isOpen [
	^stream isNotNil and: [ stream isOpen ]
]

{ #category : #testing }
SoilFilePageCache >> isRegistered [
	^ path notNil
]

{ #category : #'open/close' }
SoilFilePageCache >> open [
	self isOpen ifTrue: [ self error: 'Index store already open' ].
	self openStream
]

{ #category : #'open/close' }
SoilFilePageCache >> openStream [
	streamSemaphore critical: [  
		stream := SoilLockableStream path: path
	]
]

{ #category : #accessing }
SoilFilePageCache >> pageFaultAt: anInteger [
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

{ #category : #accessing }
SoilFilePageCache >> path: aFileReference [ 
	path := aFileReference
]

{ #category : #'instance creation' }
SoilFilePageCache >> positionOfPageIndex: anInteger [
	^ ((anInteger - 1) * self filePageSize)
]

{ #category : #writing }
SoilFilePageCache >> readHeaderPage [
	| headerPage |
	stream position: 0.
	stream next. "pageCode"
	headerPage :=  index newHeaderPage readFrom: stream.
	pagesMutex critical: [  
		pages at: 1 put: headerPage ]
]

{ #category : #accessing }
SoilFilePageCache >> readPageAt: anInteger [

	^ streamSemaphore critical: [  
		stream position: (self positionOfPageIndex: anInteger).
		(index readPageFrom: stream) 
			offset: anInteger;
			pageSize:  self filePageSize
			yourself ]
]

{ #category : #accessing }
SoilFilePageCache >> removePageAt: anIndex [ 
	^ pagesMutex critical: [  
		pages removeKey: anIndex ]
]

{ #category : #accessing }
SoilFilePageCache >> replace: oldPage with: newPage [ 
	pagesMutex critical: [  
		pages
			at: oldPage offset 
			put:newPage ]
]

{ #category : #accessing }
SoilFilePageCache >> stream [
	^ stream 
]

{ #category : #writing }
SoilFilePageCache >> writeContentsToDisk [
	stream ifNotNil: [  
		stream fileStream fsync ]
]

{ #category : #writing }
SoilFilePageCache >> writePage: aPage [ 
	| pagePosition |
	self ensureStreamIsOpen.
	streamSemaphore critical: [  
		pagePosition := self positionOfPageIndex: aPage offset.  
		stream position: pagePosition.
		aPage writeOn: stream.
		stream flush ]
]
