"
As a B+Tree, the SoilBTree has data only in the leaves, which are all instances of SoilBTreeDataPage.

The data pages form a linked list and can be traversed fast in the direction of the next page. 

There are two subclasses: one for the hearder, one for the following data pages
"
Class {
	#name : #SoilAbstractBTreeDataPage,
	#superclass : #SoilBTreePage,
	#instVars : [
		'previous',
		'next',
		'valueSize'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #testing }
SoilAbstractBTreeDataPage class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilAbstractBTreeDataPage
]

{ #category : #private }
SoilAbstractBTreeDataPage >> find: aKey with: aBTree [
	^ self

]

{ #category : #private }
SoilAbstractBTreeDataPage >> findPreviousPage: aKey with: aBTree path: aPath [
	| pageToCheck |
	pageToCheck := aPath reverse detect: [:each | (each findItemBefore: aKey) isNotNil].
	pageToCheck := aBTree pageAt: (pageToCheck findItemBefore: aKey) value.
	"if we get an index page, follow the last till reaching the data page"
	[pageToCheck isIndexPage ] whileTrue: [ pageToCheck := aBTree pageAt: pageToCheck lastItem value].
	^ pageToCheck 
]

{ #category : #utilities }
SoilAbstractBTreeDataPage >> headerSize [
	^ super headerSize  
		+ (self pointerSize * 2) "prev and next"

]

{ #category : #initialization }
SoilAbstractBTreeDataPage >> initialize [ 
	super initialize.
	next := 0. "0 means this is the last page"
	previous := 0  "0 means this is the first page"
]

{ #category : #adding }
SoilAbstractBTreeDataPage >> insertItem: anItem for: iterator [

	| newPage pageWithItem returnValue return keyIndex |

	iterator index addDirtyPage: self.

	return := SoilBTreeReturnWrapper new returnValue: (self valueAt: anItem key).
	
	keyIndex := iterator index hasUniqueKeys 
		ifTrue: [ self itemIndexForKey: anItem key ] 
		ifFalse: [ self itemIndexForKey: anItem key value: anItem value ]. 
	returnValue := self valueAt: anItem key.
	keyIndex > 0
		ifTrue: [
			"overwriting a key does not change the size of an index"
			(self itemAt: anItem key put: anItem value)  ]
		ifFalse: [
			iterator index increaseSize. 
			self addItem: anItem.
			iterator index hasUniqueKeys ifFalse: [ returnValue := nil ]].
	return := SoilBTreeReturnWrapper new returnValue: returnValue.

	self hasRoom ifTrue: [  iterator currentPage: self. ^ return ].
	"We have to split"
	newPage := iterator index splitPage: self.
	"newPage is the one with the small values"
	pageWithItem := ((self smallestKey <= anItem key)
						ifTrue: [ newPage ]
						ifFalse: [ self ]).
	iterator currentPage: pageWithItem.
	
	"check that the current and new pages are balanced"
	newPage bTreeAssertion.
	self bTreeAssertion.
	
	"we need to add the new page to the index above"
	^ return indexEntry: (newPage smallestKey -> newPage offset)
]

{ #category : #testing }
SoilAbstractBTreeDataPage >> isIndexPage [
	^false
]

{ #category : #testing }
SoilAbstractBTreeDataPage >> isLastPage [
	^ next == 0
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> next [
	^next
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> next: anInteger [
	next := anInteger
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> nextPageIn: btree [
	^btree pageAt: next
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> previous [
	^ previous
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> previous: anObject [
	previous := anObject
]

{ #category : #reading }
SoilAbstractBTreeDataPage >> readHeaderFrom: aStream [
	super readHeaderFrom: aStream.
	(version isNil or: [version > 2]) ifTrue: [ 
		previous := (aStream next: self pointerSize) asInteger].
	next := (aStream next: self pointerSize) asInteger
]

{ #category : #removing }
SoilAbstractBTreeDataPage >> remove: aKey for: aBTree [
	"remove and return the item"
	| return | 
	return :=  self itemRemoveAt: aKey ifAbsent: nil.
	return ifNotNil: [ aBTree addDirtyPage: self ].
	^ return
]

{ #category : #removing }
SoilAbstractBTreeDataPage >> removeItem: anItem for: aBTree [
	"remove and return the item"
	| return keyIndex | 
	keyIndex := aBTree hasUniqueKeys 
		ifTrue: [ self itemIndexForKey: anItem key ] 
		ifFalse: [ self itemIndexForKey: anItem key value: anItem value ]. 
	
	keyIndex = 0 ifTrue: [ ^nil ]. "nothing found"
	
	return := items at: keyIndex.
	items removeAt: keyIndex.
	aBTree addDirtyPage: self.
	^ return
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> valueSize [ 
	^ valueSize
]

{ #category : #accessing }
SoilAbstractBTreeDataPage >> valueSize: anInteger [ 
	valueSize := anInteger 
]

{ #category : #writing }
SoilAbstractBTreeDataPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	(version isNil or: [ version > 2 ]) ifTrue: [ 
	aStream
		nextPutAll: (previous asByteArrayOfSize: self pointerSize)].
	aStream
		nextPutAll: (next asByteArrayOfSize: self pointerSize)
]
