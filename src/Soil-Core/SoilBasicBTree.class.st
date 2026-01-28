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

{ #category : #removing }
SoilBasicBTree >> basicRemoveItem: anItem ifAbsent: aBlock [
	"Warning: Low level remove. If the page is empty after, the index will not work anymore, as we need minimal one key for search to work.
	Caller has to remove the empty page!"

	^ (self rootPage removeItem: anItem for: self)
		  ifNil: [ aBlock value ]
		  ifNotNil: [ :removedItem | removedItem value ]
]

{ #category : #removing }
SoilBasicBTree >> basicRemoveKey: key ifAbsent: aBlock [
	"Warning: Low level remove. If the page is empty after, the index will not work anymore, as we need minimal one key for search to work.
	Caller has to remove the empty page!"
	self hasUniqueKeys ifFalse: [ ^ self removeKeyAll: key ifAbsent: aBlock ].
	
	^ (self rootPage remove: key for: self)
		  ifNil: [ aBlock value ]
		  ifNotNil: [ :removedItem | removedItem value ]
]

{ #category : #removing }
SoilBasicBTree >> basicRemoveKey: key value: aValue ifAbsent: aBlock [
	"Warning: Low level remove. If the page is empty after, the index will not work anymore, as we need minimal one key for search to work. Caller has to remove the empty page!"

	^ (self rootPage removeItem: key -> aValue for: self)
		  ifNil: [ aBlock value ]
		  ifNotNil: [ :removedItem | removedItem value ]
]

{ #category : #accessing }
SoilBasicBTree >> dataPages [
	^ (self pages reject: [ :page | page isIndexPage or: [ page isFreePage ] ]) asArray
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

{ #category : #testing }
SoilBasicBTree >> isBTree [
	^ true
]

{ #category : #accessing }
SoilBasicBTree >> keySize: anInteger [
	super keySize: anInteger.
	"we have to set the keySize of the rootPage, too, as the page gets created before the keySize is known"
	self rootPage keySize: anInteger
]

{ #category : #removing }
SoilBasicBTree >> legacyRemovePage: aPage [
	| previousPage |
	(aPage offset > 1) ifFalse: [ ^ aPage ].
	(aPage version < 3) ifTrue: [ ^ self legacyRemovePage: aPage ].
	
	aPage isIndexPage ifTrue: [ 
		"index pages have no prev or next and are empty when we reach here"
		store removePageAt: aPage offset.
		^ aPage ].

	"We use the iterator to find the previousPage, to support old format without backlink"
	previousPage := self newIterator findPreviousPageOf: aPage.
	previousPage next: aPage next.
	
	self addDirtyPage: previousPage.
	"now remove all keys, this will update the index pages"
	
	aPage items reverseDo: [ :item | item ifNotNil: [self basicRemoveKey: item key]  ].
	"remove the page from the store"
	store removePageAt: aPage offset.
	^ aPage 
]

{ #category : #'instance creation' }
SoilBasicBTree >> newHeaderPage [
	^ SoilBTreeHeaderPage new
		offset: 1;
		lastPageOffset: 2;
		firstFreePageIndex: 0;
		pageSize: self pageSize
]

{ #category : #utilities }
SoilBasicBTree >> newIndexEntryClass [
	^ SoilNewBTreeListIndexEntry
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
	rootIndexPage setItems: OrderedCollection new.
	^newPage
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIterator [ 
	^ SoilBTreeIterator on: self 
]

{ #category : #'instance creation' }
SoilBasicBTree >> newPage [
	^ self pageClass new 
		keySize: self keySize;
		valueSize: self valueSize;
		pageSize: self pageSize;
		yourself
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

{ #category : #'instance creation' }
SoilBasicBTree >> pageClass [
	^ SoilBTreeDataPage
]

{ #category : #removing }
SoilBasicBTree >> removePage: aPage [
	| previousPage |
	"only remove if not header page (> 1)"
	(aPage offset > 1) ifFalse: [ ^ aPage ].
	
	aPage isIndexPage ifTrue: [ 
		"index pages have no prev or next and are empty when we reach here"
		store removePageAt: aPage offset.
		^ aPage ].
	
	(aPage version < 3) ifTrue: [ ^ self legacyRemovePage: aPage ].

	previousPage := self pageAt: aPage previous.
	previousPage next: aPage next.
	
	aPage next == 0 ifFalse:  [  
		"if we are not the last page"
	 	(self pageAt: aPage next) previous: aPage previous].
			
	self addDirtyPage: previousPage.
	"now remove all keys, this will update the index pages"
	
	aPage items reverseDo: [ :item | item ifNotNil: [self basicRemoveKey: item key value: item value  ]].
	"remove the page from the store"
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
	self addDirtyPage: newPage.
	^ newPage 
]

{ #category : #splitting }
SoilBasicBTree >> splitPage: page [ 
	| newPage |
	newPage := page split: store allocatePage.
	"someone else has me as previous"
	page next ~= 0 ifTrue: [(store pageAt: page next) previous: newPage offset].
	newPage next: page next.
	page next: newPage offset.
	newPage previous: page offset.
	self addDirtyPage: page.
	self addDirtyPage: newPage.
	^ newPage 
]

{ #category : #writing }
SoilBasicBTree >> writePages [
	self store flushPages
]
