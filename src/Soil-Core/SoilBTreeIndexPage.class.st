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
	| page |
	page := self findPageFor: aKey with: aBTree.
	^ page find: aKey with: aBTree
]

{ #category : #searching }
SoilBTreeIndexPage >> findPageFor: aKey with: aBTree [
	items
		reverseDo: [ :each |
			each key <= aKey 
				ifTrue: [ ^ aBTree pageAt: each value ] ].
	^nil
]

{ #category : #utilities }
SoilBTreeIndexPage >> headerSize [
	^ self indexSize
]

{ #category : #accessing }
SoilBTreeIndexPage >> insert: anItem into: aBtree [
	| indexPage newPage indexItem newIndexPage  |
	indexPage := self findPageFor: anItem key with: aBtree.
	indexPage ifNil: [ ^nil ]. "nothing to do"
	newPage := indexPage insert: anItem into: aBtree.
	newPage ifNil: [ ^nil ]. "nothing to do"
	
	indexItem := newPage smallestKey -> newPage index.
	"if the insert resulted in a split, we have to update the index, which might habe to split, too"
	self hasRoom ifTrue: [ self addItem: indexItem . ^ nil ].
	newIndexPage := aBtree splitIndexPage: self.				
	((newIndexPage smallestKey <= anItem key) 
		ifTrue: [ newIndexPage ] 
		ifFalse: [ self ]) addItem: indexItem.
	^newIndexPage
]

{ #category : #printing }
SoilBTreeIndexPage >> printOn: aStream [ 
	aStream << 'index page : #' << index asString
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
	
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: 2) asInteger ]
]

{ #category : #writing }
SoilBTreeIndexPage >> writeItemsOn: aStream [ 

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
