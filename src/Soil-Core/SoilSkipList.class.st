Class {
	#name : #SoilSkipList,
	#superclass : #SoilBasicSkipList,
	#instVars : [
		'path',
		'valueSize',
		'keySize'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #visiting }
SoilSkipList >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitSkipList: self
]

{ #category : #adding }
SoilSkipList >> addToFreePages: aPage [  
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

{ #category : #converting }
SoilSkipList >> asCopyOnWrite [
	^ SoilCopyOnWriteSkipList new
		wrapped: self;
		yourself 
]

{ #category : #'open/close' }
SoilSkipList >> close [ 
	super close.
	keySize := nil
]

{ #category : #private }
SoilSkipList >> compact [ 
	"Rewrite index file without removed items"
	self rewriteUsing: [ :item | item ]
]

{ #category : #deleting }
SoilSkipList >> destroy [
	path ensureDelete 
]

{ #category : #accessing }
SoilSkipList >> firstFreePage [
	| index | 
	index := self headerPage firstFreePageIndex.
	^ index isZero 
		ifTrue: [ ^ nil ]
		ifFalse: [ store pageAt: index ]
]

{ #category : #deleting }
SoilSkipList >> flush [
	self store flush
]

{ #category : #initialization }
SoilSkipList >> initializeFilesystem [ 
	self store initializeFilesystem
]

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self store initializeHeaderPage
]

{ #category : #initialization }
SoilSkipList >> initializeParametersFrom: aSoilSkipList [ 
	self 
		maxLevel: aSoilSkipList maxLevel;
		keySize: aSoilSkipList keySize;
		valueSize: aSoilSkipList valueSize
]

{ #category : #testing }
SoilSkipList >> isRegistered [
	^ path notNil
]

{ #category : #accessing }
SoilSkipList >> keySize [
	^ keySize ifNil: [
		keySize := super keySize ]
]

{ #category : #accessing }
SoilSkipList >> keySize: anInteger [
	super keySize: anInteger.
	keySize := anInteger
]

{ #category : #'instance creation' }
SoilSkipList >> newHeaderPage [
	^ SoilSkipListHeaderPage new
		offset: 1;
		lastPageIndex: 1;
		firstFreePageIndex: 0;
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

{ #category : #reindexing }
SoilSkipList >> newPluggableRewriter [
	^ SoilPluggableIndexRewriter new 
		index: self
]

{ #category : #'opening/closing' }
SoilSkipList >> open [
	self isOpen ifTrue: [ self error: 'Index already open' ].
	self store open
]

{ #category : #'instance creation' }
SoilSkipList >> pageClass [
	^ SoilSkipListDataPage
]

{ #category : #accessing }
SoilSkipList >> path [

	^ path
]

{ #category : #accessing }
SoilSkipList >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #'as yet unclassified' }
SoilSkipList >> persistentIndex [
	^ self 
]

{ #category : #initialization }
SoilSkipList >> rewriteUsing: aBlock [
	"write new index file and add all items. Use aBlock to 
	enable converting items"
	SoilPluggableIndexRewriter new 
		index: self;
		indexBlock: [ :idx | idx  ];
		itemBlock: aBlock;
		cleanRemoved;
		run
]

{ #category : #converting }
SoilSkipList >> thePersistentInstance [
	^ self
	
]

{ #category : #accessing }
SoilSkipList >> valueSize [
	^ valueSize ifNil: [ 
		valueSize := super valueSize ]
]

{ #category : #accessing }
SoilSkipList >> valueSize: anInteger [ 
	super valueSize: anInteger.
	valueSize := anInteger
]

{ #category : #writing }
SoilSkipList >> writePages [
	self store flushPages
]
