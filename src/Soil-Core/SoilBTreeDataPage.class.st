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

{ #category : #accessing }
SoilBTreeDataPage >> biggestKey [
	^ self isLastPage 
		ifTrue: [ (2 raisedTo: (keySize * 8)) - 1 ]
		ifFalse: [ items last key ]
]

{ #category : #private }
SoilBTreeDataPage >> find: aKey with: aBTree [
	^ self

]

{ #category : #testing }
SoilBTreeDataPage >> hasItems [
	^ items notEmpty
]

{ #category : #utilities }
SoilBTreeDataPage >> headerSize [
	^ self indexSize + self pointerSize
]

{ #category : #initialization }
SoilBTreeDataPage >> initialize [ 
	super initialize.
	"0 means this is the last page"
	next := 0
]

{ #category : #accessing }
SoilBTreeDataPage >> insert: anItem into: anIterator [
	| newPage choosenPage |
	self hasRoom ifTrue: [ anIterator currentPage: self. self addItem: anItem. ^ nil ].
	
	"No room, we have to split"	
	newPage := anIterator index splitPage: self.
	
	choosenPage := 
	((self biggestKey < anItem key)
						ifTrue: [ newPage ]
						ifFalse: [ self ]).
	choosenPage addItem: anItem.
	anIterator currentPage: choosenPage.
	^newPage 


]

{ #category : #testing }
SoilBTreeDataPage >> isLastPage [
	^ next == 0
]

{ #category : #accessing }
SoilBTreeDataPage >> itemAt: anInteger ifAbsent: aBlock [
	^ items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | items at: ind ]
		ifNone: [ aBlock value ]
]

{ #category : #accessing }
SoilBTreeDataPage >> itemAt: key put: anObject [ 
	| removedItem |
	removedItem := self itemRemoveAt: key ifAbsent: [ KeyNotFound signal: 'this method is just for replacing items'].
	items add: (key -> anObject).
	dirty := true.
	^ removedItem
]

{ #category : #accessing }
SoilBTreeDataPage >> itemBefore: key [ 
	| item |
	item := items at: key ifAbsent: nil.
	^ items before: item ifAbsent: nil
]

{ #category : #accessing }
SoilBTreeDataPage >> lastItem [

	^ items ifEmpty: [ nil ] ifNotEmpty: [ :itms | itms last ]
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
SoilBTreeDataPage >> writeNextOn: aStream [
	aStream
		nextPutAll: (next asByteArrayOfSize: self pointerSize)
]

{ #category : #'reading-writing' }
SoilBTreeDataPage >> writeOn: aStream [ 
	super writeOn: aStream.
	self 
		writeNextOn: aStream;
		writeItemsOn: aStream
]
