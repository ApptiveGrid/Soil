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

{ #category : #testing }
SoilBTreeIndexPage >> hasRoom [
	^ self headerSize + ((items size + 1) * (self keySize + self pointerSize)) <= self pageSize
]

{ #category : #utilities }
SoilBTreeIndexPage >> headerSize [
	^ self indexSize
]

{ #category : #searching }
SoilBTreeIndexPage >> insertItem: item for: iterator [
	| foundItem return newPage  |
	
	foundItem := self findKey: item key.
	
	return := (iterator index pageAt: foundItem value) insertItem: item for: iterator.
	return indexEntryNeeded ifFalse: [  ^ return ].
	
	"We need to add to this index page"
	self addItem: return indexEntry.
	self hasRoom ifTrue: [  ^ return indexEntry: nil].
		
	"no space, we have to split"
	newPage := iterator index splitIndexPage: self.
	"we need to add the new page to the index above"
	^ return indexEntry: (newPage smallestKey -> newPage index)
]

{ #category : #accessing }
SoilBTreeIndexPage >> itemAt: key put: anObject [ 
	| removedItem |
	removedItem := self itemRemoveAt: key ifAbsent: [ KeyNotFound signal: 'this method is just for replacing items'].
	items add: (key -> anObject).
	dirty := true.
	^ removedItem
]

{ #category : #printing }
SoilBTreeIndexPage >> printOn: aStream [ 
	aStream << 'index page : #' << index asString
]

{ #category : #'reading-writing' }
SoilBTreeIndexPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readItemsFrom: aStream
]

{ #category : #'reading-writing' }
SoilBTreeIndexPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: self pointerSize) asInteger ]
]

{ #category : #accessing }
SoilBTreeIndexPage >> valueSize: anInteger [
	"ignore, not used, the index pages store the pageID as the value, size is static defined in #pointerSize"
]

{ #category : #'reading-writing' }
SoilBTreeIndexPage >> writeItemsOn: aStream [ 

	aStream
		nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: self pointerSize)]
]

{ #category : #'reading-writing' }
SoilBTreeIndexPage >> writeOn: aStream [ 
	super writeOn: aStream.
	self writeItemsOn: aStream
]
