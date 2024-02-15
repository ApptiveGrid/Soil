"
As a B+Tree, the SoilBTree has data only in the leaves, which are all instances of SoilBTreeDataPage.

The data pages form a linked list and can be traversed fast in the direction of the next page. 

There is a special subclass for the first page (the header).


"
Class {
	#name : #SoilBTreeDataPage,
	#superclass : #SoilBTreePage,
	#instVars : [
		'next',
		'valueSize'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeDataPage class >> pageCode [ 
	^ 4
]

{ #category : #private }
SoilBTreeDataPage >> find: aKey with: aBTree [
	^ self

]

{ #category : #utilities }
SoilBTreeDataPage >> headerSize [
	^ super headerSize  
		+ self pointerSize "next"
		+ 2 "items size"
]

{ #category : #initialization }
SoilBTreeDataPage >> initialize [ 
	super initialize.
	"0 means this is the last page"
	next := 0
]

{ #category : #adding }
SoilBTreeDataPage >> insertItem: anItem for: iterator [

	| newPage pageWithItem return |

	return := SoilBTreeReturnWrapper new returnValue: ((self associationAt: anItem key ifAbsent: nil) ifNotNil: [:item | item value]).
	self addItem: anItem.
	self hasRoom ifTrue: [  iterator currentPage: self. ^ return ].
	"We have to split"
	newPage := iterator index splitPage: self.
	"newPage is the one with the small values"
	pageWithItem := ((self smallestKey > anItem key)
						ifTrue: [ newPage ]
						ifFalse: [ self ]).
	iterator currentPage: pageWithItem.
	"we need to add the new page to the index above"
	^ return indexEntry: (newPage smallestKey -> newPage index)
]

{ #category : #testing }
SoilBTreeDataPage >> isLastPage [
	^ next == 0
]

{ #category : #accessing }
SoilBTreeDataPage >> next [
	^next
]

{ #category : #accessing }
SoilBTreeDataPage >> next: anInteger [
	next := anInteger
]

{ #category : #accessing }
SoilBTreeDataPage >> nextPageIn: btree [
	^btree pageAt: next
]

{ #category : #'reading-writing' }
SoilBTreeDataPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self 
		readNextFrom: aStream;
		readItemsFrom: aStream
]

{ #category : #'reading-writing' }
SoilBTreeDataPage >> readNextFrom: aStream [
	
	next := (aStream next: self pointerSize) asInteger.
]

{ #category : #accessing }
SoilBTreeDataPage >> valueSize [ 
	^ valueSize
]

{ #category : #accessing }
SoilBTreeDataPage >> valueSize: anInteger [ 
	valueSize := anInteger 
]

{ #category : #'reading-writing' }
SoilBTreeDataPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream
		nextPutAll: (next asByteArrayOfSize: self pointerSize)
]
