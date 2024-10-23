"
Abstract superclass for the SoilBtree B+Tree index.

This class just contains shared code between the main BTree and the copy-on-write version.

See SoilBTree for more information
"
Class {
	#name : #SoilBasicBTree,
	#superclass : #SoilIndex,
	#instVars : [
		'dirtyPages'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #testing }
SoilBasicBTree class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBasicBTree
]

{ #category : #adding }
SoilBasicBTree >> addDirtyPage: aPage [ 
	dirtyPages add: aPage
]

{ #category : #converting }
SoilBasicBTree >> asCopyOnWrite [
	^ SoilCopyOnWriteBTree new
		wrapped: self;
		yourself 
]

{ #category : #accessing }
SoilBasicBTree >> dataPages [
	^ (self pages reject: [ :page | page isIndexPage ]) asArray
]

{ #category : #accessing }
SoilBasicBTree >> dirtyPages [
	^ dirtyPages
]

{ #category : #accessing }
SoilBasicBTree >> flush [
	self store flush
]

{ #category : #testing }
SoilBasicBTree >> hasHeaderPage [
	^ store hasHeaderPage 
]

{ #category : #accessing }
SoilBasicBTree >> indexPages [
	^ (self pages select: [ :page | page isIndexPage ]) asArray
]

{ #category : #initialization }
SoilBasicBTree >> initialize [ 
	super initialize.
	dirtyPages := Set new
]

{ #category : #initialization }
SoilBasicBTree >> initializeFilesystem [ 
	self store initializeFilesystem
]

{ #category : #initialization }
SoilBasicBTree >> initializeHeaderPage [
	| rootIndexPage |
	self store 
		initializeHeaderPage.
	"we create the first index page as the root here"	
	rootIndexPage := self newRootPage.
	self store pageAt: rootIndexPage offset put: rootIndexPage
]

{ #category : #accessing }
SoilBasicBTree >> keySize: anInteger [
	super keySize: anInteger.
	"we have to set the keySize of the rootPage, too, as the page gets created before the keySize is known"
	self rootPage keySize: anInteger
]

{ #category : #'instance creation' }
SoilBasicBTree >> newHeaderPage [
	^ SoilBTreeHeaderPage new
		offset: 1;
		lastPageIndex: 2;
		firstFreePageIndex: 0;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIndexPage [
	^ SoilBTreeIndexPage new 
		keySize: self keySize;
		pageSize: self pageSize;
		offset: self store nextPageOffset;
		yourself
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIndexPageFromRoot: rootIndexPage [
	| newPage |
	newPage := self newIndexPage.
	self store pageAt: newPage offset put: newPage.
	"now move over all items"
	newPage setItems: rootIndexPage items.
	rootIndexPage setItems: SortedCollection new.
	^newPage
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIterator [ 
	^ SoilBTreeIterator on: self 
]

{ #category : #'instance creation' }
SoilBasicBTree >> newRootPage [
	^ SoilBTreeRootPage new
		offset: 2;
		keySize: self keySize;
		pageSize: self pageSize
]

{ #category : #'open/close' }
SoilBasicBTree >> open [
 	self isOpen ifTrue: [ self error: 'Index already open' ].
	self store open
]

{ #category : #initialization }
SoilBasicBTree >> pageClass [
	^ SoilBTreeDataPage
]

{ #category : #removing }
SoilBasicBTree >> recyclePage: aPage [
	"the header stays untouched even it it gets empty"
	aPage isHeaderPage ifTrue: [ ^ aPage ].
	"remove page from chain of item pages"
	self removePage: aPage. 
	"add page to free list chain"
	^ self addToFreePages: aPage
]

{ #category : #removing }
SoilBasicBTree >> removeDirtyPage: aPage [ 
	dirtyPages remove: aPage 
]

{ #category : #removing }
SoilBasicBTree >> removeKey: key ifAbsent: aBlock [

	^ (self rootPage remove: key for: self)
		  ifNil: [ aBlock value ]
		  ifNotNil: [ :removedItem | removedItem value ]
]

{ #category : #removing }
SoilBasicBTree >> removePage: aPage [
	| iterator previousPage |
	(aPage offset > 1) ifFalse: [ ^ aPage ].

	"We use the iterator to find the previousPage, to change it's next pointer to my next"
	iterator := self newIterator. 
	previousPage := iterator findPreviousPageOf: aPage. 
	previousPage next: aPage next.
	
	"now remove all keys, this will update the index pages"
	
	aPage items reverseDo: [ :item | item ifNotNil: [self removeKey: item key]  ].
	
	"finally remove the page from the store"
	store removePageAt: aPage offset.
	^ aPage 

]

{ #category : #accessing }
SoilBasicBTree >> rootPage [
	^ self store pageAt: 2
]

{ #category : #accessing }
SoilBasicBTree >> size [
	^ self headerPage size
]

{ #category : #splitting }
SoilBasicBTree >> splitIndexPage: page [ 
	| newPage |
	newPage := page split: self newIndexPage.
	self store pageAt: newPage offset put: newPage.
	^ newPage 
]

{ #category : #splitting }
SoilBasicBTree >> splitPage: page [ 
	| newPage |
	newPage := page split: store allocatePage.
	newPage offset: self store nextPageOffset.
	newPage next: page next.
	page next: newPage offset.
	self store pageAt: newPage offset put: newPage.
	^ newPage 
]

{ #category : #writing }
SoilBasicBTree >> writePages [
	self store flushPages
]
