"
As a B+Tree, the SoilBTree has data only in the leaves, which are all instances of SoilBTreeDataPage.

The data pages form a linked list and can be traversed fast in the direction of the next page. 

There are two subclasses: one for the hearder, one for the following data pages
"
Class {
	#name : #SoilAbstractBTreeDataPage,
	#superclass : #SoilBTreePage,
	#instVars : [
		'next',
		'valueSize'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #testing }
SoilAbstractBTreeDataPage class >> isAbstract [

	^ self == SoilAbstractBTreeDataPage
]

{ #category : #private }
SoilAbstractBTreeDataPage >> find: aKey with: aBTree [
	^ self

]

{ #category : #private }
SoilAbstractBTreeDataPage >> findPreviousPage: aKey with: aBTree path: aPath [
	| pageToCheck |
	pageToCheck := aPath reverse detect: [:each | (each itemBefore: aKey) isNotNil].
	pageToCheck := aBTree pageAt: (pageToCheck itemBefore: aKey) value.
	"if we get an index page, follow the last till reaching the data page"
	[pageToCheck isIndexPage ] whileTrue: [ pageToCheck := aBTree pageAt: pageToCheck lastItem value].
	^ pageToCheck 
]

{ #category : #utilities }
SoilAbstractBTreeDataPage >> headerSize [
	^ super headerSize  
		+ self pointerSize "next"

]

{ #category : #initialization }
SoilAbstractBTreeDataPage >> initialize [ 
	super initialize.
	"0 means this is the last page"
	next := 0
]

{ #category : #adding }
SoilAbstractBTreeDataPage >> insertItem: anItem for: iterator [

	| newPage pageWithItem return |

	return := SoilBTreeReturnWrapper new returnValue: (self valueAt: anItem key).
	self addItem: anItem.
	self hasRoom ifTrue: [  iterator currentPage: self. ^ return ].
	"We have to split"
	newPage := iterator index splitPage: self.
	"newPage is the one with the small values"
	pageWithItem := ((self smallestKey <= anItem key)
						ifTrue: [ newPage ]
						ifFalse: [ self ]).
	iterator currentPage: pageWithItem.
	
	"check that the current and new pages are balanced"
	self flag: #TODO. "should be moved to a consistency checker"
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

{ #category : #reading }
SoilAbstractBTreeDataPage >> readFrom: aStream [
	super readFrom: aStream.
	next := (aStream next: self pointerSize) asInteger
]

{ #category : #removing }
SoilAbstractBTreeDataPage >> remove: aKey for: aBTree [
	"remove and return the item"
	^ self itemRemoveAt: aKey ifAbsent: nil
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
	aStream
		nextPutAll: (next asByteArrayOfSize: self pointerSize)
]
