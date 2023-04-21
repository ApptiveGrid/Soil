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

{ #category : #accessing }
SoilBTreePage >> itemCapacity [
	^ ((self pageSize - self headerSize) / (self keySize + self valueSize)) floor
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
SoilBTreePage >> numberOfItems [
	^ items size
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
