Class {
	#name : #SoilBTree,
	#superclass : #Object,
	#instVars : [
		'path',
		'store'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTree >> at: key [ 
	^ self 
		at: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self  ] 
]

{ #category : #accessing }
SoilBTree >> at: anObject ifAbsent: aBlock [
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilBTree >> at: aKeyObject put: anObject [

	| key |
	key := (aKeyObject asSkipListKeyOfSize: self keySize) asInteger.
	self rootPage insert: key -> anObject into: self.
]

{ #category : #'initialize-release' }
SoilBTree >> close [
	self store close
]

{ #category : #deleting }
SoilBTree >> destroy [
	path ensureDelete 
]

{ #category : #private }
SoilBTree >> find: aString [ 
	^ self newIterator 
		find: (aString asSkipListKeyOfSize: self keySize) asInteger
]

{ #category : #accessing }
SoilBTree >> headerPage [
	^ self store headerPage
]

{ #category : #initialization }
SoilBTree >> initializeFilesystem [ 
	self store initializeFilesystem
]

{ #category : #initialization }
SoilBTree >> initializeHeaderPage [
	self store initializeHeaderPage
]

{ #category : #accessing }
SoilBTree >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilBTree >> keySize: anInteger [
	self headerPage keySize: anInteger.
	self rootPage keySize: anInteger
]

{ #category : #'instance creation' }
SoilBTree >> newFileStore [
	^ SoilPagedFileIndexStoreBTree new
		index: self
]

{ #category : #'instance creation' }
SoilBTree >> newHeaderPage [
	^ SoilBTreeHeaderPage new
		index: 1;
		lastPageIndex: 2;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilBTree >> newIndexPage [
	^ SoilBTreeIndexPage new 
		keySize: self keySize;
		valueSize: self valueSize;
		pageSize: self pageSize;
		yourself
]

{ #category : #'instance creation' }
SoilBTree >> newIndexPageFromRoot: rootIndexPage [
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
SoilBTree >> newIterator [ 
	^ SoilBTreeIterator on: self 
]

{ #category : #'instance creation' }
SoilBTree >> newPage [
	^ self pageClass new 
		keySize: self keySize;
		valueSize: self valueSize;
		pageSize: self pageSize;
		yourself
]

{ #category : #'instance creation' }
SoilBTree >> newRootPage [
	^ SoilBTreeRootPage new
		index: 2;
		valueSize: self valueSize;
		keySize: self keySize;
		pageSize: self pageSize
]

{ #category : #'instance creation' }
SoilBTree >> open [
	self store open
]

{ #category : #accessing }
SoilBTree >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
]

{ #category : #initialization }
SoilBTree >> pageClass [
	^ SoilBTreeDataPage
]

{ #category : #accessing }
SoilBTree >> pageSize [
	^ 4 * 1024
]

{ #category : #accessing }
SoilBTree >> pages [
	^ self store pages
]

{ #category : #accessing }
SoilBTree >> path [

	^ path
]

{ #category : #accessing }
SoilBTree >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #'instance creation' }
SoilBTree >> readPageFrom: aStream [
	^ SoilBTreePage readPageFrom: aStream
]

{ #category : #accessing }
SoilBTree >> rootPage [
	^ self store pageAt: 2
]

{ #category : #accessing }
SoilBTree >> size [
	"We iterate over all elements to get the size. Slow!"
	^ self newIterator size 
]

{ #category : #splitting }
SoilBTree >> splitIndexPage: page [ 
	| newPage |
	newPage := page split: self newIndexPage.
	newPage index: self store nextPageIndex.
	self store pageAt: newPage index put: newPage.
	^ newPage 
]

{ #category : #splitting }
SoilBTree >> splitPage: page [ 
	| newPage |
	newPage := page split: store newPage.
	newPage index: self store nextPageIndex.
	page next: newPage index.
	self store pageAt: newPage index put: newPage.
	^ newPage 
]

{ #category : #splitting }
SoilBTree >> splitRootIndexPage: page [ 
	| newPage newPage2 |
	newPage := page split: self newIndexPage.
	newPage index: self store nextPageIndex.
	self store pageAt: newPage index put: newPage.
	
	newPage2 := self newIndexPage.
	newPage2 index: self store nextPageIndex.
	self store pageAt: newPage2 index put: newPage2.
	^ { newPage . newPage2 }
]

{ #category : #accessing }
SoilBTree >> store [
	^ store ifNil: [ 
		store := self newFileStore ]
]

{ #category : #accessing }
SoilBTree >> valueSize [
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilBTree >> valueSize: anInteger [
	self headerPage valueSize: anInteger.
	self rootPage valueSize: anInteger
]

{ #category : #writing }
SoilBTree >> writePages [
	self store flushPages
]
