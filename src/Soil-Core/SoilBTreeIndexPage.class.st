"
As a B+Tree, the SoilBTree index has index nodes.

The entries are indexKey -> pageNumber

The pageNumber can be that of another index page or of a data page.

For the root index page, we have a subclass SoilBTreeRootPage
"
Class {
	#name : #SoilBTreeIndexPage,
	#superclass : #SoilBTreePage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeIndexPage class >> pageCode [ 
	^ 5
]

{ #category : #private }
SoilBTreeIndexPage >> find: aKey with: aBTree [
	| item page |
	item := self findKey: aKey.
	page := aBTree pageAt: item value.
	^ page find: aKey with: aBTree
]

{ #category : #searching }
SoilBTreeIndexPage >> findKey: aKey [
	items
		reverseDo: [ :each |
			each key <= aKey 
				ifTrue: [ ^ each ] ].
	^nil
]

{ #category : #private }
SoilBTreeIndexPage >> findPreviousPage: aKey with: aBTree path: aPath [
	| item page  |
	"we record the path of all index pages taken to find the key"
	aPath add: self.
	item := self findKey: aKey.
	page := aBTree pageAt: item value.
	^ page findPreviousPage: aKey with: aBTree path: aPath
]

{ #category : #initialization }
SoilBTreeIndexPage >> initializeInIndex: aSoilSkipList [ 
	keySize := aSoilSkipList keySize
]

{ #category : #adding }
SoilBTreeIndexPage >> insertItem: item for: iterator [
	| foundItem return newPage  |
	
	foundItem := self findKey: item key.
	
	return := (iterator index pageAt: foundItem value) insertItem: item for: iterator.
	return indexEntryNeeded ifFalse: [  ^ return ].
	
	"We need to add to this index page"
	self addItem: return indexEntry.
	iterator index addDirtyPage: self.
	self hasRoom ifTrue: [  ^ return indexEntry: nil].
		
	"no space, we have to split"
	newPage := iterator index splitIndexPage: self.
	
	"check that the current and new pages are balanced"
	self flag: #TODO. "should be moved to a consistency checker"
	newPage bTreeAssertion.
	self bTreeAssertion.
	
	
	"we need to add the new page to the index above"
	^ return indexEntry: (newPage smallestKey -> newPage offset)
]

{ #category : #testing }
SoilBTreeIndexPage >> isIndexPage [
	^ true
]

{ #category : #initialization }
SoilBTreeIndexPage >> latestVersion [
	^ 1
]

{ #category : #testing }
SoilBTreeIndexPage >> needsCleanup [
	^ false
]

{ #category : #printing }
SoilBTreeIndexPage >> printOn: aStream [ 
	aStream << 'index page : #' << offset asString
]

{ #category : #reading }
SoilBTreeIndexPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readItemsFrom: aStream
]

{ #category : #reading }
SoilBTreeIndexPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	"calculate the maximum number of items that can be stored in this
	page so we spend that amount removing the need for the collection 
	to grow"
	items := OrderedCollection new: self itemCapacity.
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	numberOfItems timesRepeat: [ 
		items add: ((aStream next: self keySize) asInteger -> (aStream next: self pointerSize) asInteger ) ]
]

{ #category : #removing }
SoilBTreeIndexPage >> remove: aKey for: aBTree [
	| item page ret  |
	
	item := self findKey: aKey.
	page := aBTree pageAt: item value.
	ret := page remove: aKey for: aBTree.
	"if the key is in the index, we have to update or remove"
	(self hasKey: aKey) ifTrue: [
				(ret notNil and: [page isNotEmpty])
					ifTrue: [ item key: page items first key]
				   ifFalse: [self itemRemoveAt: aKey]].
	^ ret
]

{ #category : #accessing }
SoilBTreeIndexPage >> valueSize [
	"our values are indexes of other pages"
	^ self pointerSize
]

{ #category : #accessing }
SoilBTreeIndexPage >> valueSize: anInteger [
	"ignore, not used, the index pages store the pageID as the value, size is static defined in #pointerSize"
]
