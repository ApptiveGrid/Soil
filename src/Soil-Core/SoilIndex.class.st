"
This is the abstract superclass for Soil Indexes. For now, we have two implementations: SoilBTree and SoilSkipList

Indexes 
	- are stored on disk in Pages (see SoilIndexPage) with a size of 4KB.
	- Implement a dictionary style API key-value
	
But note: the key is an integer created by calling #asIndexKeyOfSize:, the value is a ByteArray.

Access and Iteration over the index is implemented by the SoilIndexIterator (the index fowards every access there).

Indexes can be used stand alone or with a transaction of a database. This is the case when the index is used for a SoilIndexedDictionary
"
Class {
	#name : #SoilIndex,
	#superclass : #Object,
	#instVars : [
		'id',
		'store',
		'dirtyPages'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #adding }
SoilIndex >> addDirtyPage: aPage [ 
	dirtyPages 
		at: aPage offset 
		ifAbsentPut: [ aPage ]
]

{ #category : #adding }
SoilIndex >> addToFreePages: aPage [  
	| currentFreePage newFreePage |
	newFreePage := aPage asSoilFreePage.
	store pageAt: aPage offset put: newFreePage.
	currentFreePage := self firstFreePage
		ifNil: [ 
			"if there is no first free page yet make aPage the
			first free page"
			self headerPage firstFreePageIndex: newFreePage offset.
			^ newFreePage ].
	"if there is a first free page start scanning from here for a
	free page that has room to store another free page"
	[ currentFreePage hasRoom ] whileFalse: [ 
		"if there is no room for the page to store and the current
		free page does not have a next pointer we make aPage the 
		next"
		currentFreePage next isZero 
			ifTrue: [
				currentFreePage next: newFreePage offset.
				^ newFreePage  ]
			ifFalse: [ currentFreePage := store pageAt: currentFreePage next ]].
	currentFreePage addPage: newFreePage.
	^ newFreePage 
]

{ #category : #'instance creation' }
SoilIndex >> allocatePage [
	| page |
	page := self newPage 
		offset: (self nextFreePageIndex
			ifNil: [ self nextPageOffset ]).
	self store pageAt: page offset put: page.
	self addDirtyPage: page.
	^ page
]

{ #category : #private }
SoilIndex >> at: key [ 
	^ self 
		at: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilIndex >> at: anObject ifAbsent: aBlock [
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilIndex >> at: aKeyObject put: anObject [
	self newIterator 
		at: aKeyObject 
		put: anObject
]

{ #category : #accessing }
SoilIndex >> atIndex: anInteger [
	^ self newIterator atIndex: anInteger 
]

{ #category : #accessing }
SoilIndex >> basicAt: key put: anObject [
	^ self newIterator 
		basicAt: key 
		put: anObject 
]

{ #category : #removing }
SoilIndex >> cleanRemoved: aPage [
	aPage cleanRemovedIn: self
]

{ #category : #'as yet unclassified' }
SoilIndex >> cleanUpToVersion: aNumberOrNil [ 
		SoilIndexCleaner new 
			index: self;
			readVersion: aNumberOrNil;
			clean.
]

{ #category : #'open/close' }
SoilIndex >> close [
	self store close.
	store := nil
]

{ #category : #private }
SoilIndex >> compact [ 
	"Rewrite index file without removed items"
	self rewriteUsing: [ :item | item ]
]

{ #category : #utilities }
SoilIndex >> decreaseSize [
	self headerPage decreaseSize.
	self addDirtyPage: self headerPage.
]

{ #category : #accessing }
SoilIndex >> dirtyPages [
	^ dirtyPages
]

{ #category : #enumerating }
SoilIndex >> do: aBlock [
	self newIterator do: aBlock
]

{ #category : #private }
SoilIndex >> find: key [ 
	^ self newIterator 
		find: key
]

{ #category : #accessing }
SoilIndex >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilIndex >> first: anInteger [
	^ self newIterator first: anInteger
]

{ #category : #accessing }
SoilIndex >> firstFreePage [
	| index | 
	index := self headerPage firstFreePageIndex.
	^ index isZero 
		ifTrue: [ ^ nil ]
		ifFalse: [ store pageAt: index ]
]

{ #category : #accessing }
SoilIndex >> firstPage [
	^ self headerPage
]

{ #category : #accessing }
SoilIndex >> flushCachedPages [
	store flushCachedPages
]

{ #category : #testing }
SoilIndex >> hasHeaderPage [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> headerPage [
	^ self store headerPage
]

{ #category : #accessing }
SoilIndex >> id [

	^ id
]

{ #category : #accessing }
SoilIndex >> id: anObject [

	id := anObject
]

{ #category : #utilities }
SoilIndex >> increaseSize [
	self headerPage increaseSize.
	self addDirtyPage: self headerPage. 
]

{ #category : #accessing }
SoilIndex >> indexKey: aString [
	^ aString asIndexKeyOfSize: self keySize
]

{ #category : #testing }
SoilIndex >> isEmpty [
	^ self store headerPage isEmpty
]

{ #category : #testing }
SoilIndex >> isOpen [
	^ store isNotNil and: [ store isOpen ]
]

{ #category : #testing }
SoilIndex >> isRegistered [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilIndex >> keySize: anInteger [
	anInteger isZero ifTrue: [ Error signal: 'keySize cannot be zero yet' ].
	self headerPage keySize: anInteger
]

{ #category : #accessing }
SoilIndex >> last [
	^ self newIterator last
]

{ #category : #accessing }
SoilIndex >> lastPage [
	^ self newIterator lastPage
]

{ #category : #'as yet unclassified' }
SoilIndex >> markAllDirty [ 
	store pages do: [ :page | self addDirtyPage: page ]
]

{ #category : #accessing }
SoilIndex >> maxLevel [
	"ignored, this allows to switch SkiList and BTree easily"
]

{ #category : #accessing }
SoilIndex >> maxLevel: anIntegeer [
	"ignored, this allows to switch SkiList and BTree easily"
]

{ #category : #'instance creation' }
SoilIndex >> newFileStore [
	^ SoilPagedFileIndexStore new
		index: self
]

{ #category : #utilities }
SoilIndex >> newIndexEntryClass [
	self subclassResponsibility
]

{ #category : #'instance creation' }
SoilIndex >> newIterator [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SoilIndex >> newPage [
	^ self subclassResponsibility
]

{ #category : #reindexing }
SoilIndex >> newPluggableRewriter [
	^ SoilPluggableIndexRewriter new 
		index: self
]

{ #category : #private }
SoilIndex >> nextFreePageIndex [ 
	| firstFreePage freePageIndex |
	firstFreePage := self firstFreePage ifNil: [ 
		^ nil ].
	^ firstFreePage hasFreePages 
		ifTrue: [ 
			freePageIndex := firstFreePage removeFirstIndex.
			self removePageWithIndexIfPresent: freePageIndex.
			self addDirtyPage: firstFreePage.
			freePageIndex  ] 
		ifFalse: [ 
			"if firstFreePage has a next pointer we set that as 
			new first free page. Next will return 0 if there is no
			next page"
			freePageIndex := firstFreePage next.
			self headerPage firstFreePageIndex: firstFreePage next.
			self removePageWithIndexIfPresent: firstFreePage offset.

			self addDirtyPage: self headerPage.
			firstFreePage offset ]
]

{ #category : #initialization }
SoilIndex >> nextPageOffset [
	| offset |
	offset := store nextPageOffset.
	self addDirtyPage: store headerPage.
	^ offset 
]

{ #category : #accessing }
SoilIndex >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
]

{ #category : #'instance creation' }
SoilIndex >> pageClass [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> pageSize [
	^ 4 * 1024
]

{ #category : #accessing }
SoilIndex >> pages [
	^ self store pages
]

{ #category : #accessing }
SoilIndex >> persistentIndex [
	^ self 
]

{ #category : #'instance creation' }
SoilIndex >> readPageClassFrom: aStream [
	^ SoilIndexPage readPageClassFrom: aStream
]

{ #category : #'instance creation' }
SoilIndex >> readPageFrom: aStream [
	| page |
	page := (self readPageClassFrom: aStream) basicNew.
	page 
		pageSize: self pageSize;
		initializeInIndex: self. 
	^ page readFrom: aStream 
]

{ #category : #removing }
SoilIndex >> recyclePage: aPage [
	"the header stays untouched even it it gets empty"
	aPage isHeaderPage ifTrue: [ ^ aPage ].
	"remove page from chain of item pages"
	self removePage: aPage. 
	"add page to free list chain"
	^ self addToFreePages: aPage
]

{ #category : #removing }
SoilIndex >> removeDirtyPage: aPage [ 
	dirtyPages removeKey: aPage offset
]

{ #category : #removing }
SoilIndex >> removeKey: key [ 
	^ self
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndex >> removeKey: key ifAbsent: aBlock [
	| page index |
	page := self newIterator 
		find: key;
		currentPage.
	^ ((index := page indexOfKey: (self indexKey: key)) > 0)
		ifTrue: [ 
			self decreaseSize.
			(page itemRemoveIndex: index) value ]
		ifFalse: [ aBlock value ]
]

{ #category : #removing }
SoilIndex >> removePage: aPage [ 
	^ self subclassResponsibility
]

{ #category : #removing }
SoilIndex >> removePageWithIndexIfPresent: anInteger [ 
	(store includesPageAt: anInteger) ifTrue: [ 
		store removePageAt: anInteger ]
]

{ #category : #public }
SoilIndex >> reopen [
	self 
		close;
		open
]

{ #category : #enumerating }
SoilIndex >> reverseDo: aBlock [
	self newIterator reverseDo: aBlock
]

{ #category : #initialization }
SoilIndex >> rewriteUsing: aBlock [
	"write new index file and add all items. Use aBlock to 
	enable converting items"
	self newPluggableRewriter
		indexBlock: [ :idx | idx  ];
		itemBlock: aBlock;
		cleanRemoved;
		run
]

{ #category : #accessing }
SoilIndex >> size [
	"We iterate over all elements to get the size. Slow!"
	^ self newIterator size 
]

{ #category : #accessing }
SoilIndex >> store [
	^ store ifNil: [ 
		store := self newFileStore ]
]

{ #category : #accessing }
SoilIndex >> store: anObject [
	anObject index: self.
	store := anObject
]

{ #category : #converting }
SoilIndex >> thePersistentInstance [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> valueSize [
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilIndex >> valueSize: anInteger [
	self headerPage valueSize: anInteger
]

{ #category : #enumerating }
SoilIndex >> values [ 
	^ self newIterator values
]

{ #category : #writing }
SoilIndex >> writeContentsToDisk [
	self store writeContentsToDisk 
]
