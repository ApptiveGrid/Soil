Class {
	#name : #SoilSkipList,
	#superclass : #Object,
	#instVars : [
		'path',
		'store'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #converting }
SoilSkipList >> asModifiableIndex [
	^ self copy
		store: store asCopyOnWriteStore;
		yourself 
]

{ #category : #converting }
SoilSkipList >> asWritableIndex [
	| writableStore |
	writableStore := store isCopyOnWrite
		ifTrue: [ store underlyingStore ]
		ifFalse: [ store ].
	^ self copy 
		store: writableStore;
		yourself
]

{ #category : #private }
SoilSkipList >> at: aByteArray [ 
	^ self 
		at: aByteArray 
		ifAbsent: [ Error signal: 'no found' ]
]

{ #category : #private }
SoilSkipList >> at: anObject ifAbsent: aBlock [
	path ifNil: [ aBlock value ].
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilSkipList >> at: aKeyObject put: anObject [
	| key iterator page index newPage |
	key := (aKeyObject asSkipListKeyOfSize: self keySize) asInteger.
	iterator := self iterator.
	iterator find: key.
	page := iterator page.
	index := page indexOfKey: key.
	(index > 0)
		ifTrue: [ page itemAt: key put: anObject ] 
		ifFalse: [ 
			page hasRoom 
				ifTrue: [ iterator page addItem: (key -> anObject) ]
				ifFalse: [ 
					newPage := self splitPage: iterator.
					((page biggestKey < key)
						ifTrue: [ newPage ]
						ifFalse: [ page ])
							addItem: (key -> anObject) ] ].
	^ anObject
]

{ #category : #accessing }
SoilSkipList >> atIndex: anInteger [ 
	| current iterator |
	iterator := self iterator.
	current := iterator first.
	2 to: anInteger do: [ :idx |
		current := iterator next ].
	^ current value
]

{ #category : #'as yet unclassified' }
SoilSkipList >> beCopyOnWrite [
	store := SoilCopyOnWriteIndexStore new
		index: self;
		underlyingStore: (SoilPagedFileIndexStore new
		 index: self)
]

{ #category : #'initialize-release' }
SoilSkipList >> close [
	self store close
]

{ #category : #deleting }
SoilSkipList >> destroy [
	path ensureDelete 
]

{ #category : #enumerating }
SoilSkipList >> do: aBlock [
	path ifNotNil: [ 
		self iterator do: aBlock ]
]

{ #category : #private }
SoilSkipList >> find: aString [ 
	^ self iterator 
		find: (aString asSkipListKeyOfSize: self keySize) asInteger
]

{ #category : #accessing }
SoilSkipList >> first: anInteger [ 
	| iterator col |
	iterator := self iterator.
	col := OrderedCollection new.
	anInteger timesRepeat: [ 
		(iterator next)
			ifNotNil: [ :value | col add: value ]
			ifNil: [ ^ col ]].
	^ col
]

{ #category : #accessing }
SoilSkipList >> firstItem [
	^ self headerPage firstItem
]

{ #category : #accessing }
SoilSkipList >> firstPage [
	^ self store pageAt: 1
]

{ #category : #accessing }
SoilSkipList >> flush [
	self store flush
]

{ #category : #'as yet unclassified' }
SoilSkipList >> headerPage [
	^ self store headerPage
]

{ #category : #initialization }
SoilSkipList >> initializeFilesystem [ 
	store initializeFilesystem
]

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self store initializeHeaderPage
]

{ #category : #testing }
SoilSkipList >> isEmpty [
	^ self store headerPage hasItems not
]

{ #category : #'public/accessing' }
SoilSkipList >> iterator [ 
	^ SoilSkipListIterator on: self 
]

{ #category : #accessing }
SoilSkipList >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilSkipList >> keySize: anInteger [
	anInteger isZero ifTrue: [ self halt ].
	self headerPage keySize: anInteger
]

{ #category : #accessing }
SoilSkipList >> last [
	^ self store lastPage lastItem
]

{ #category : #accessing }
SoilSkipList >> lastPage [
	self shouldBeImplemented.
]

{ #category : #actions }
SoilSkipList >> load [
	self pageFaultAt: 1
]

{ #category : #accessing }
SoilSkipList >> maxLevel [
	"^ maxLevel"
	^ self headerPage maxLevel
]

{ #category : #accessing }
SoilSkipList >> maxLevel: anInteger [ 
	"maxLevel := anInteger "
	store headerPage maxLevel: anInteger 
]

{ #category : #'instance creation' }
SoilSkipList >> newHeaderPage [
	^ SoilSkipListHeaderPage new
		index: 1;
		lastPageIndex: 1;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilSkipList >> newPage [
	^ self pageClass new 
		initializeLevel: self maxLevel;
		keySize: self keySize;
		valueSize: self valueSize;
		pageSize: self pageSize;
		yourself
]

{ #category : #'instance creation' }
SoilSkipList >> newPageRegistry [
	^ SoilPagedFileIndexStore new
		index: self
]

{ #category : #'instance creation' }
SoilSkipList >> newWritablePage [
self halt.
	^ SoilWritableSkipListPage new
		level: self maxLevel;
		size: 4096;
		keySize: 16;
		valueSize: 8.
		
		
]

{ #category : #opening }
SoilSkipList >> open [
	self store open
]

{ #category : #accessing }
SoilSkipList >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
]

{ #category : #'instance creation' }
SoilSkipList >> pageClass [
	^ SoilSkipListTruncPage
]

{ #category : #accessing }
SoilSkipList >> pageSize [
	^ 4 * 1024
]

{ #category : #accessing }
SoilSkipList >> pages [
	^ self store pages
]

{ #category : #accessing }
SoilSkipList >> path [

	^ path
]

{ #category : #accessing }
SoilSkipList >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #accessing }
SoilSkipList >> size [ 
	^ self store allItems size - 2
]

{ #category : #'as yet unclassified' }
SoilSkipList >> splitPage: aIterator [ 
	| newPage page |
	page := aIterator page.
	newPage := page split: store newPage.
	newPage index: self store nextPageIndex.
	newPage level to: 1 by: -1  do: [ :level |
		(level > page level)
			ifTrue: [ 
				newPage rightAt: level put: ((aIterator levelAt: level) rightAt: level).
				(aIterator levelAt: level) rightAt: level put: newPage index ]
			ifFalse: [ 
				(page rightAt: level) ifNotNil: [ :r | 
					newPage rightAt: level put: r ].
				page rightAt: level put: newPage index ]].
	self store pageAt: newPage index put: newPage.
	^ newPage 
]

{ #category : #accessing }
SoilSkipList >> store [
	^ store ifNil: [ 
		store := self newPageRegistry ]
]

{ #category : #accessing }
SoilSkipList >> store: anObject [
	anObject index: self.
	store := anObject
]

{ #category : #accessing }
SoilSkipList >> valueSize [
	"^ 8"
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilSkipList >> valueSize: anInteger [ 
	"valueSize := anInteger"
	self headerPage valueSize: anInteger 
]

{ #category : #writing }
SoilSkipList >> writeHeaderPage [
	self store writeHeaderPage
]

{ #category : #writing }
SoilSkipList >> writePages [
	self store flushPages
]
