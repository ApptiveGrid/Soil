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
SoilBTreeDataPage >> insert: anItem into: aBtree [
	| newPage |
	self hasRoom ifTrue: [ self addItem: anItem. ^ nil ].
	
	"No room, we have to split"	
	newPage := aBtree splitPage: self.
	((self biggestKey < anItem key)
						ifTrue: [ newPage ]
						ifFalse: [ self ]) addItem: anItem.
	^newPage 


]

{ #category : #testing }
SoilBTreeDataPage >> isLastPage [
	^ next == 0
]

{ #category : #accessing }
SoilBTreeDataPage >> lastItem [
	| item maxKey |
	items ifEmpty: [ ^ nil ].
	maxKey := (2 raisedTo: (keySize * 8)) - 1. 
	item := items last.
	^ (item key = maxKey)
		ifTrue: [ items at: items size - 1 ]
		ifFalse: [ item ] 
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
