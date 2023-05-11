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
SoilBTree >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilBTree >> first: anInteger [ 
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

{ #category : #testing }
SoilBTree >> isEmpty [
	^ self store headerPage hasItems not
]

{ #category : #accessing }
SoilBTree >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilBTree >> keySize: anInteger [
	self headerPage keySize: anInteger.
	"we have to set the keySize of the rootPage, too, as the page gets created before the keySize is known"
	self rootPage keySize: anInteger
]

{ #category : #accessing }
SoilBTree >> last [
	^ self newIterator last
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
	^ SoilBTreePage readPageFrom: aStream keySize: self keySize valueSize: self valueSize
]

{ #category : #removing }
SoilBTree >> removeKey: key [ 
	^ self
		removeKey: key 
		ifAbsent: [ KeyNotFound signal: key ]
]

{ #category : #removing }
SoilBTree >> removeKey: aString ifAbsent: aBlock [
	| page index key |
	key := (aString asSkipListKeyOfSize: self keySize) asInteger.
	page := self newIterator 
		find: key;
		page.
	^ ((index := page indexOfKey: key) > 0) 
		ifTrue: [ (page itemRemoveIndex: index) value ]
		ifFalse: [ aBlock value ]
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
	self headerPage valueSize: anInteger
]

{ #category : #writing }
SoilBTree >> writePages [
	self store flushPages
]
