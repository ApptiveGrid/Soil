Class {
	#name : #SoilBTreeIndexPage,
	#superclass : #SoilBTreePage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'as yet unclassified' }
SoilBTreeIndexPage class >> pageCode [ 
	^ 5
]

{ #category : #private }
SoilBTreeIndexPage >> find: aKey with: aBTree [
	| page |
	page := self findPageFor: aKey with: aBTree.
	^ page find: aKey with: aBTree
]

{ #category : #searching }
SoilBTreeIndexPage >> findPageFor: aKey with: aBTree [
	self flag: #TODO. 
	"iterate without creatihg the copy"
	self items reversed detect: [ :item | item key <= aKey  ] ifFound: [ :found | ^ aBTree pageAt: found value asInteger]
]

{ #category : #utilities }
SoilBTreeIndexPage >> headerSize [
	^ self indexSize
]

{ #category : #accessing }
SoilBTreeIndexPage >> insert: anItem into: aBtree [
	| newPage indexItem |
		
	newPage := (self findPageFor: anItem key with: aBtree) insert: anItem into: aBtree.
	newPage ifNil: [ ^nil ]. "nothing to do"
	
	indexItem := newPage smallestKey -> (newPage index asByteArrayOfSize: 2).
	"if the insert resulted in a split, we have to update the index, which might habe to split, too"
	self hasRoom ifTrue: [ self addItem: indexItem . ^ nil ].
	self halt. "untested"
	newPage := aBtree splitIndexPage: self.
	
	((self biggestKey < newPage smallestKey)
						ifTrue: [ newPage ]
						ifFalse: [ self ]) addItem: indexItem.
	^newPage
	
	
	
]

{ #category : #reading }
SoilBTreeIndexPage >> readFrom: aStream [ 
	super readFrom: aStream.
	keySize := (aStream next: 2) asInteger.
	valueSize := (aStream next: 2) asInteger.

	self readItemsFrom: aStream
]

{ #category : #writing }
SoilBTreeIndexPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	
	self flag: #fixme. "duplicated code from superclass, should not be needed if valueSize is correct"
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: 2) ]
]

{ #category : #writing }
SoilBTreeIndexPage >> writeItemsOn: aStream [ 
	self flag: #fixme. "duplicated code from superclass, should not be needed if valueSize is correct"
	aStream
		nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: 2)]
]

{ #category : #writing }
SoilBTreeIndexPage >> writeOn: aStream [ 
	super writeOn: aStream.
	aStream
		nextPutAll: (keySize asByteArrayOfSize: 2);
		nextPutAll: (valueSize asByteArrayOfSize: 2).
	self 
		writeItemsOn: aStream
]
