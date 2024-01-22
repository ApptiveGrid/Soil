Class {
	#name : #SoilIndexItemsPage,
	#superclass : #SoilIndexPage,
	#instVars : [
		'items'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilIndexItemsPage class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexItemsPage
]

{ #category : #adding }
SoilIndexItemsPage >> addItem: anAssociation [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexItemsPage >> associationAt: anInteger [ 
	^ self
		associationAt: anInteger 
		ifAbsent: nil
]

{ #category : #accessing }
SoilIndexItemsPage >> associationAt: anInteger ifAbsent: aBlock [
	^ items 
		findBinary: [ :each | anInteger - each key] 
		ifNone: [ aBlock value ].
]

{ #category : #accessing }
SoilIndexItemsPage >> firstItem [

	^ items isNotEmpty ifTrue: [ items first ]
]

{ #category : #testing }
SoilIndexItemsPage >> hasRoom [
	| used itemSize |
	itemSize := self keySize + self valueSize.
	used := self headerSize + (items size * itemSize).
	^ used <= (self pageSize - itemSize)
]

{ #category : #utilities }
SoilIndexItemsPage >> headerSize [
	^ super headerSize + 8 "last transaction number"
]

{ #category : #accessing }
SoilIndexItemsPage >> indexOfKey: anInteger [ 
	items withIndexDo: [ :each :idx |
		(each key = anInteger) ifTrue: [ ^ idx ] ].
	^ 0
]

{ #category : #initialization }
SoilIndexItemsPage >> initialize [
	items := SortedCollection new
]

{ #category : #testing }
SoilIndexItemsPage >> isEmpty [
	^ items isEmpty 
]

{ #category : #accessing }
SoilIndexItemsPage >> itemAfter: key [ 
	| i item |
	i := items findBinaryIndex: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	(i = items size) ifTrue: [ ^ nil].
	item := items at: i + 1.
	^ item
]

{ #category : #accessing }
SoilIndexItemsPage >> itemAt: anInteger ifAbsent: aBlock [
	^ items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | items at: ind ]
		ifNone: aBlock 
]

{ #category : #accessing }
SoilIndexItemsPage >> itemAt: key put: anObject [ 
	| removedItem |
	removedItem := self itemRemoveAt: key ifAbsent: [ KeyNotFound signal: 'this method is just for replacing items'].
	items add: (key -> anObject).
	dirty := true.
	^ removedItem
]

{ #category : #accessing }
SoilIndexItemsPage >> itemBefore: key [

	| item |
	item := items findBinary: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	^ items before: item ifAbsent: nil
]

{ #category : #accessing }
SoilIndexItemsPage >> itemCapacity [
	^ ((self pageSize - self headerSize) / (self keySize + self valueSize)) floor
]

{ #category : #accessing }
SoilIndexItemsPage >> itemRemoveAt: key [ 
	^ self 
		itemRemoveAt: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilIndexItemsPage >> itemRemoveAt: anInteger ifAbsent: aBlock [
	| item |
	items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | item := items removeAt: ind ]
		ifNone: [ ^ aBlock value ].
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilIndexItemsPage >> itemRemoveIndex: anInteger [
	| item |
	item := items at: anInteger.
	items removeAt: anInteger.
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilIndexItemsPage >> items [
	^ items
]

{ #category : #accessing }
SoilIndexItemsPage >> keyOrClosestAfter: key [ 
	"find the closest key in this page. This returns the exact key if 
	present or the key that comes after. Else returns nil. This is useful if we enter the
	list at an unknown point"
	items isEmpty ifTrue: [ ^ nil ].
	self lastKey < key ifTrue: [ ^ nil ].
	^ items 
		findBinaryIndex: [ :each | key - each key ] 
		do: [ :e | (items at: e) key] 
		ifNone: [ :a :b | 
			(items at: (b min: items size)) key ]
]

{ #category : #accessing }
SoilIndexItemsPage >> lastItem [

	^ items isNotEmpty ifTrue: [ items last ] ifFalse: [ nil ]
]

{ #category : #accessing }
SoilIndexItemsPage >> lastKey [

	^ items isNotEmpty ifTrue: [ items last key ]
]

{ #category : #accessing }
SoilIndexItemsPage >> numberOfItems [
	^ items size
]

{ #category : #copying }
SoilIndexItemsPage >> postCopy [ 
	super postCopy.
	items := items copy.
]

{ #category : #accessing }
SoilIndexItemsPage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #accessing }
SoilIndexItemsPage >> smallestKey [
	^ items first key
]

{ #category : #accessing }
SoilIndexItemsPage >> valueAt: anInteger [ 
	^ self 
		valueAt: anInteger 
		ifAbsent: nil 
]

{ #category : #accessing }
SoilIndexItemsPage >> valueAt: anInteger ifAbsent: aBlock [
	^ (self 
		associationAt: anInteger
		ifAbsent: aBlock) value
]

{ #category : #accessing }
SoilIndexItemsPage >> valueSize [
	^ self subclassResponsibility
]
