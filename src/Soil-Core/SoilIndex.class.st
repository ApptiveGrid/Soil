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
		'store'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #adding }
SoilIndex >> addDirtyPage: aPage [ 
	
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

{ #category : #'open/close' }
SoilIndex >> close [
	self store close.
	store := nil
]

{ #category : #'as yet unclassified' }
SoilIndex >> decreaseSize [
	self headerPage decreaseSize 
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

{ #category : #testing }
SoilIndex >> hasPagesToMaintain [
	^ false 	
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

{ #category : #'as yet unclassified' }
SoilIndex >> increaseSize [
	self headerPage increaseSize 
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

{ #category : #'instance creation' }
SoilIndex >> newIterator [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SoilIndex >> newPage [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
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
SoilIndex >> pagesToMaintain [ 
	^ #()
]

{ #category : #'instance creation' }
SoilIndex >> readPageClassFrom: aStream [
	^ SoilIndexPage readPageClassFrom: aStream
]

{ #category : #'instance creation' }
SoilIndex >> readPageFrom: aStream [
	| page |
	page := (self readPageClassFrom: aStream) basicNew.
	page initializeInIndex: self. 
	^ page readFrom: aStream 
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
