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

{ #category : #accessing }
SoilSkipList >> acceptSoil: aSoilVisitor [ 
	^ aSoilVisitor visitSkipList: self
]

{ #category : #'instance creation' }
SoilSkipList >> allocatePage [
	^ self newPage 
		offset: (self nextFreePage 
			ifNotNil: [ :freePage | freePage offset ]
			ifNil: [ store nextPageOffset ])
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

{ #category : #private }
SoilSkipList >> nextFreePage [
	| firstPage freePage |
	firstPage := self firstFreePage ifNil: [ 
		^ nil ].
	^ firstPage hasFreePages 
		ifTrue: [ 
			freePage := store pageAt: firstPage removeFirstIndex.
			self addDirtyPage: freePage.
			freePage  ] 
		ifFalse: [ 
			self headerPage firstFreePageIndex: 0.
			self addDirtyPage: self headerPage.
			firstPage ]
				
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
