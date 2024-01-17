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
SoilSkipList >> isPersistent [
	^ path notNil
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
SoilSkipList >> newFileStore [
	^ SoilPagedFileIndexStore new
		index: self
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

{ #category : #'as yet unclassified' }
SoilSkipList >> newReIndexer [
	^ SoilReindexer new 
		index: self
]

{ #category : #'opening/closing' }
SoilSkipList >> open [
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
SoilSkipList >> reIndex [
	self newReIndexer run
]

{ #category : #'as yet unclassified' }
SoilSkipList >> reIndexUsing: itemBlock [ 
	self newReIndexer 
		itemBlock: itemBlock;
		run
]

{ #category : #'instance creation' }
SoilSkipList >> readPageFrom: aStream [
	^ (SoilIndexPage readPageFrom: aStream keySize: self keySize valueSize: self valueSize)
		pageSize: self pageSize 
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
