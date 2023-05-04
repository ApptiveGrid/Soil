Class {
	#name : #SoilBTreePage,
	#superclass : #SoilSkipListPage,
	#instVars : [
		'items',
		'keySize',
		'valueSize'
	],
	#category : #'Soil-Core-Index-BTree'
}

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
	^ items 
		detect: [:each | each key = anInteger ] 
		ifNone: [ nil ]
]

{ #category : #accessing }
SoilBTreePage >> biggestKey [
	^ items last key
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
	dirty := true
]

{ #category : #testing }
SoilBTreePage >> isEmpty [
	^ items isEmpty 
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
		ifAbsent: [ KeyNotFound signal: key ]
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
SoilBTreePage >> items [
	^ items
]

{ #category : #writing }
SoilBTreePage >> itemsSizeSize [
	^ 2
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
SoilBTreePage >> numberOfItems [
	^ items size
]

{ #category : #reading }
SoilBTreePage >> readItemsFrom: aStream [ 
	| numberOfItems |
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: self valueSize) ]
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
	^ (self associationAt: anInteger) value
]

{ #category : #accessing }
SoilBTreePage >> valueSize [ 
	^ valueSize
]

{ #category : #accessing }
SoilBTreePage >> valueSize: anInteger [ 
	valueSize := anInteger 
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
