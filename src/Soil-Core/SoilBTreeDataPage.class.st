Class {
	#name : #SoilBTreeDataPage,
	#superclass : #SoilBTreePage,
	#instVars : [
		'next'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'as yet unclassified' }
SoilBTreeDataPage >> biggestKey [
	^ self isLastPage 
		ifTrue: [ (2 raisedTo: (keySize * 8)) - 1 ]
		ifFalse: [ items last key ]
]

{ #category : #private }
SoilBTreeDataPage >> find: aKey with: aBTree [
	^ self valueAt: aKey.

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

{ #category : #accessing }
SoilBTreeDataPage >> pointerSize [
	^ 2
]

{ #category : #'instance creation' }
SoilBTreeDataPage >> readFrom: aStream [ 
	dirty := false.
	self readIndexFrom: aStream.
	self readNextFrom: aStream
]

{ #category : #'instance creation' }
SoilBTreeDataPage >> readNextFrom: aStream [
	
	next := (aStream next: self pointerSize) asInteger.
]

{ #category : #writing }
SoilBTreeDataPage >> writeOn: aStream [ 
	dirty := false.
	aStream 
		nextPutAll: (index asByteArrayOfSize: self indexSize);
		nextPutAll: (next asByteArrayOfSize: self pointerSize)
]
