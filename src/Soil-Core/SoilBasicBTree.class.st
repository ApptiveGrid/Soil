"
Abstract superclass for the SoilBtree B+Tree index.

This class just contains shared code between the main BTree and the copy-on-write version.

See SoilBTree for more information
"
Class {
	#name : #SoilBasicBTree,
	#superclass : #SoilIndex,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #testing }
SoilBasicBTree class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBasicBTree
]

{ #category : #converting }
SoilBasicBTree >> asCopyOnWrite [
	^ SoilCopyOnWriteBTree new
		wrapped: self;
		yourself 
]

{ #category : #accessing }
SoilBasicBTree >> dataPages [
	^ (self pages select: [ :page | page isDataPage ]) asArray
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
	^ (self pages reject: [ :page | page isDataPage ]) asArray
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
	self store pageAt: rootIndexPage index put: rootIndexPage
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
		index: 1;
		lastPageIndex: 2;
		lastFreePageIndex: 0;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIndexPage [
	^ SoilBTreeIndexPage new 
		keySize: self keySize;
		pageSize: self pageSize;
		index: self store nextPageIndex;
		yourself
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIndexPageFromRoot: rootIndexPage [
	| newPage |
	newPage := self newIndexPage.
	self store pageAt: newPage index put: newPage.
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
		index: 2;
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
SoilBasicBTree >> removeKey: key ifAbsent: aBlock [
	| return |
	return := self rootPage remove: key for: self.
	^ return ifNil: [aBlock value]
]

{ #category : #accessing }
SoilBasicBTree >> rootPage [
	^ self store pageAt: 2
]

{ #category : #splitting }
SoilBasicBTree >> splitIndexPage: page [ 
	| newPage |
	newPage := page split: self newIndexPage.
	self store pageAt: newPage index put: newPage.
	^ newPage 
]

{ #category : #splitting }
SoilBasicBTree >> splitPage: page [ 
	| newPage |
	newPage := page split: store newPage.
	newPage index: self store nextPageIndex.
	page next: newPage index.
	self store pageAt: newPage index put: newPage.
	^ newPage 
]

{ #category : #writing }
SoilBasicBTree >> writePages [
	self store flushPages
]
