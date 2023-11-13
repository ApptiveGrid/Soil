Class {
	#name : #SoilBasicBTree,
	#superclass : #Object,
	#instVars : [
		'store'
	],
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
		wrappedBTree: self;
		yourself 
]

{ #category : #accessing }
SoilBasicBTree >> at: key [ 
	^ self 
		at: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self  ] 
]

{ #category : #accessing }
SoilBasicBTree >> at: anObject ifAbsent: aBlock [
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilBasicBTree >> at: aKeyObject put: anObject [

	self newIterator 
		at: aKeyObject 
		put: anObject.

]

{ #category : #accessing }
SoilBasicBTree >> atIndex: anInteger [
	| current iterator |
	iterator := self newIterator.
	current := iterator first.
	2 to: anInteger do: [ :idx |
		current := iterator next ].
	^ current value
]

{ #category : #'open/close' }
SoilBasicBTree >> close [
	self store close
]

{ #category : #private }
SoilBasicBTree >> find: aString [ 
	^ self newIterator 
		find: (aString asSkipListKeyOfSize: self keySize) asInteger
]

{ #category : #accessing }
SoilBasicBTree >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilBasicBTree >> first: anInteger [ 
	| iterator col |
	iterator := self newIterator.
	col := OrderedCollection new.
	anInteger timesRepeat: [ 
		(iterator next)
			ifNotNil: [ :value | col add: value ]
			ifNil: [ ^ col ]].
	^ col
]

{ #category : #accessing }
SoilBasicBTree >> flush [
	self store flush
]

{ #category : #accessing }
SoilBasicBTree >> flushCachedPages [
	store flushCachedPages
]

{ #category : #accessing }
SoilBasicBTree >> headerPage [
	^ self store headerPage
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

{ #category : #testing }
SoilBasicBTree >> isEmpty [
	^ self store headerPage hasItems not
]

{ #category : #testing }
SoilBasicBTree >> isRegistered [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilBasicBTree >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilBasicBTree >> keySize: anInteger [
	self headerPage keySize: anInteger.
	"we have to set the keySize of the rootPage, too, as the page gets created before the keySize is known"
	self rootPage keySize: anInteger
]

{ #category : #accessing }
SoilBasicBTree >> last [
	^ self newIterator last
]

{ #category : #accessing }
SoilBasicBTree >> maxLevel: anIntegeer [
	"ignored, this allows to switch SkiList and BTree easily"
]

{ #category : #'instance creation' }
SoilBasicBTree >> newFileStore [
	^ SoilPagedFileIndexStore new
		index: self
]

{ #category : #'instance creation' }
SoilBasicBTree >> newHeaderPage [
	^ SoilBTreeHeaderPage new
		index: 1;
		lastPageIndex: 2;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIndexPage [
	^ SoilBTreeIndexPage new 
		keySize: self keySize;
		pageSize: self pageSize;
		yourself
]

{ #category : #'instance creation' }
SoilBasicBTree >> newIndexPageFromRoot: rootIndexPage [
	| newPage |
	newPage := self newIndexPage.
	newPage index: self store nextPageIndex.
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
		index: 2;
		keySize: self keySize;
		pageSize: self pageSize
]

{ #category : #'open/close' }
SoilBasicBTree >> open [
	self store open
]

{ #category : #accessing }
SoilBasicBTree >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
]

{ #category : #initialization }
SoilBasicBTree >> pageClass [
	^ SoilBTreeDataPage
]

{ #category : #accessing }
SoilBasicBTree >> pageSize [
	^ 4 * 1024
]

{ #category : #accessing }
SoilBasicBTree >> pages [
	^ self store pages
]

{ #category : #'instance creation' }
SoilBasicBTree >> readPageFrom: aStream [
	^ SoilBTreePage readPageFrom: aStream keySize: self keySize valueSize: self valueSize
]

{ #category : #removing }
SoilBasicBTree >> removeKey: key [ 
	^ self
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilBasicBTree >> removeKey: aString ifAbsent: aBlock [
	| page index key |
	key := (aString asSkipListKeyOfSize: self keySize) asInteger.
	page := self newIterator 
		find: key;
		currentPage.
	^ ((index := page indexOfKey: key) > 0) 
		ifTrue: [ (page itemRemoveIndex: index) value ]
		ifFalse: [ aBlock value ]
]

{ #category : #accessing }
SoilBasicBTree >> rootPage [
	^ self store pageAt: 2
]

{ #category : #accessing }
SoilBasicBTree >> size [
	"We iterate over all elements to get the size. Slow!"
	^ self newIterator size 
]

{ #category : #splitting }
SoilBasicBTree >> splitIndexPage: page [ 
	| newPage |
	newPage := page split: self newIndexPage.
	newPage index: self store nextPageIndex.
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

{ #category : #accessing }
SoilBasicBTree >> store [
	^ store ifNil: [ 
		store := self newFileStore ]
]

{ #category : #accessing }
SoilBasicBTree >> store: anObject [
	anObject index: self.
	store := anObject
]

{ #category : #converting }
SoilBasicBTree >> thePersistentInstance [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilBasicBTree >> valueSize [
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilBasicBTree >> valueSize: anInteger [
	self headerPage valueSize: anInteger
]

{ #category : #writing }
SoilBasicBTree >> writePages [
	self store flushPages
]
