Class {
	#name : #SoilBTreePage,
	#superclass : #SoilIndexPage,
	#instVars : [
		'items',
		'keySize',
		'lastTransaction'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreePage class >> indexClass [ 
	^ SoilBTree 
]

{ #category : #accessing }
SoilBTreePage class >> pageCode [
	"abstract"
	^0
]

{ #category : #adding }
SoilBTreePage >> addItem: anAssociation [ 
	items add: anAssociation.
	dirty := true
]

{ #category : #accessing }
SoilBTreePage >> associationAt: anInteger [ 
	^ self
		associationAt: anInteger 
		ifAbsent: [ nil ]
]

{ #category : #accessing }
SoilBTreePage >> associationAt: anInteger ifAbsent: aBlock [
	^ items 
		detect: [:each | each key = anInteger ] 
		ifNone: aBlock
]

{ #category : #accessing }
SoilBTreePage >> biggestKey [
	^ items last key
]

{ #category : #'as yet unclassified' }
SoilBTreePage >> find: aKey with: aBTree [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilBTreePage >> firstItem [
	^ items first
]

{ #category : #testing }
SoilBTreePage >> hasRoom [
	^ self headerSize + ((items size + 1) * (self keySize + self valueSize)) <= self pageSize
]

{ #category : #utilities }
SoilBTreePage >> headerSize [
	self subclassResponsibility
]

{ #category : #accessing }
SoilBTreePage >> indexOfKey: anInteger [ 
	items withIndexDo: [ :each :idx |
		(each key = anInteger) ifTrue: [ ^ idx ] ].
	^ 0
]

{ #category : #initialization }
SoilBTreePage >> initialize [ 
	super initialize.
	items := SortedCollection new.
	lastTransaction := 0.
	dirty := true
]

{ #category : #'as yet unclassified' }
SoilBTreePage >> insert: anItem into: aBtree [ 
	^ self subclassResponsibility
]

{ #category : #testing }
SoilBTreePage >> isEmpty [
	^ items isEmpty 
]

{ #category : #testing }
SoilBTreePage >> isOlderThan: aVersionNumber [ 
	^ lastTransaction <= aVersionNumber 
]

{ #category : #'as yet unclassified' }
SoilBTreePage >> itemAfter: key [ 
	| i item |
	i := items findBinaryIndex: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	(i = items size) ifTrue: [ ^ nil].
	item := items at: i + 1.
	(item key >= ((2 raisedTo: 64) - 1)) ifTrue: [ ^ nil ].
	^ item
]

{ #category : #accessing }
SoilBTreePage >> itemCapacity [
	^ ((self pageSize - self headerSize) / (self keySize + self valueSize)) floor
]

{ #category : #accessing }
SoilBTreePage >> itemRemoveAt: key [ 
	^ self 
		itemRemoveAt: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilBTreePage >> itemRemoveAt: anInteger ifAbsent: aBlock [
	| item |
	items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | item := items removeAt: ind ]
		ifNone: [ ^ aBlock value ].
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilBTreePage >> itemRemoveIndex: anInteger [
	| item |
	item := items at: anInteger.
	items removeAt: anInteger.
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilBTreePage >> items [
	^ items
]

{ #category : #accessing }
SoilBTreePage >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilBTreePage >> keySize: anInteger [ 
	keySize := anInteger
]

{ #category : #accessing }
SoilBTreePage >> lastTransaction [
	^ lastTransaction
]

{ #category : #accessing }
SoilBTreePage >> lastTransaction: anInteger [ 
	lastTransaction := anInteger
]

{ #category : #accessing }
SoilBTreePage >> numberOfItems [
	^ items size
]

{ #category : #accessing }
SoilBTreePage >> pointerSize [
	^ 2
]

{ #category : #reading }
SoilBTreePage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readLastTransactionFrom: aStream
]

{ #category : #reading }
SoilBTreePage >> readItemsFrom: aStream [ 
	| numberOfItems |
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: self valueSize) ]
]

{ #category : #writing }
SoilBTreePage >> readLastTransactionFrom: aStream [ 
	lastTransaction := (aStream next: 8) asInteger.
]

{ #category : #initialization }
SoilBTreePage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #accessing }
SoilBTreePage >> smallestKey [
	^ items first key
]

{ #category : #private }
SoilBTreePage >> split: newPage [
	| middle |
	
	newPage 
		index: index.
	middle := (items size / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	
	^ newPage
]

{ #category : #accessing }
SoilBTreePage >> valueAt: anInteger [ 
	^ self 
		valueAt: anInteger 
		ifAbsent: nil 
]

{ #category : #accessing }
SoilBTreePage >> valueAt: anInteger ifAbsent: aBlock [
	^ (self 
		associationAt: anInteger
		ifAbsent: aBlock) value
]

{ #category : #writing }
SoilBTreePage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream nextPutAll: (lastTransaction asByteArrayOfSize: 8)
]

{ #category : #writing }
SoilBTreePage >> writeItemsOn: aStream [ 
	aStream
		nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: self valueSize)]
]
