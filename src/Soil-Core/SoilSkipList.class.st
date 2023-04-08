Class {
	#name : #SoilSkipList,
	#superclass : #SoilBasicSkipList,
	#instVars : [
		'path'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #converting }
SoilSkipList >> asCopyOnWrite [
	^ SoilCopyOnWriteSkipList new
		wrappedSkipList: self;
		yourself 
]

{ #category : #'initialize-release' }
SoilSkipList >> close [
	self store close
]

{ #category : #deleting }
SoilSkipList >> destroy [
	path ensureDelete 
]

{ #category : #accessing }
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

{ #category : #private }
SoilSkipList >> isPersistent [
	^ path notNil
]

{ #category : #testing }
SoilSkipList >> isRegistered [
	^ path notNil
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

{ #category : #'instance creation' }
SoilSkipList >> newWritablePage [
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

{ #category : #'instance creation' }
SoilSkipList >> pageClass [
	^ SoilSkipListTruncPage
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
	^ self store allItems size 
]

{ #category : #converting }
SoilSkipList >> thePersistentInstance [
	"| writableStore |
	writableStore := store isCopyOnWrite
		ifTrue: [ store wrappedStore ]
		ifFalse: [ store ].
	^ self copy 
		store: writableStore;
		yourself"
	^ self
	
]

{ #category : #writing }
SoilSkipList >> writeHeaderPage [
	self store writeHeaderPage
]

{ #category : #writing }
SoilSkipList >> writePages [
	self store flushPages
]
