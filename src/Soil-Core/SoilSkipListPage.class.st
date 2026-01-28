"
A skiplist stores data in pages (of 4KB), which are all instances of the two subclasses of this class.

The data pages form a linked list and can be traversed fast in the direction of the next page.

There is a special subclass for the first page (the header).
"
Class {
	#name : #SoilSkipListPage,
	#superclass : #SoilIndexItemsPage,
	#instVars : [
		'left',
		'right',
		'valueSize'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilSkipListPage class >> indexClass [
	^ SoilSkipList 
]

{ #category : #testing }
SoilSkipListPage class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilSkipListPage 
]

{ #category : #accessing }
SoilSkipListPage >> biggestKey [
	^ self isLastPage 
		ifTrue: [ (2 raisedTo: (keySize * 8)) - 1 ]
		ifFalse: [ self lastKey ]
]

{ #category : #removing }
SoilSkipListPage >> cleanRemoved [
	items removeAllSuchThat: [ :each | each value isRemoved ].
	needWrite := true
]

{ #category : #removing }
SoilSkipListPage >> cleanRemovedIn: index [
	"index not needed for the SkipList"
	self cleanRemoved
]

{ #category : #accessing }
SoilSkipListPage >> firstItemIndexForKey: key [ 
	| index |
	index := items 
		findBinaryIndex: [ :each | key - each key ] 
		do: [ :idx | idx ] 
		ifNone: [ :l :u | ^ 0 ].
	[ index > 1 and: [ (items at: index - 1) key = key ] ] whileTrue: [ 
		index := index - 1 ].
	^ index 
]

{ #category : #initialization }
SoilSkipListPage >> initialize [ 
	super initialize.
	lastTransaction := 0.
	needWrite := true
]

{ #category : #initialization }
SoilSkipListPage >> initializeLevel: maxLevel [
	| promote level |
	level := 1. 
	promote := true.
	[ (level < maxLevel) and: [ promote ] ] whileTrue: [ 
		level := level + 1.
		promote := self class random next > 0.5 ].
	left := Array new: level withAll: 0.
	right := Array new: level withAll: 0. 
]

{ #category : #testing }
SoilSkipListPage >> isLastPage [
	^ (right at: 1) == 0
]

{ #category : #accessing }
SoilSkipListPage >> left [
	^ left
]

{ #category : #accessing }
SoilSkipListPage >> leftAt: anInteger [ 
	^ left at: anInteger 
]

{ #category : #accessing }
SoilSkipListPage >> leftAt: anInteger put: anObject [ 
	left at: anInteger put: anObject.
	needWrite := true
]

{ #category : #writing }
SoilSkipListPage >> leftSize [
	"this fixes the maximum number of pages to 32 bits which should be enough. This
	17TB when using a page size of 4k"
	^ 4
]

{ #category : #accessing }
SoilSkipListPage >> level [ 
	^ right size
]

{ #category : #accessing }
SoilSkipListPage >> next [
	^ self rightAt: 1
]

{ #category : #copying }
SoilSkipListPage >> postCopy [ 
	super postCopy.
	right := right copy.
	left := left copy
]

{ #category : #accessing }
SoilSkipListPage >> previous [
	^ self leftAt: 1
]

{ #category : #reading }
SoilSkipListPage >> readHeaderFrom: aStream [ 
	super readHeaderFrom: aStream.
	self readLastTransactionFrom: aStream
]

{ #category : #reading }
SoilSkipListPage >> readLevelsFrom: aStream [ 
	| level |
	level := aStream next asInteger.
	right := Array new: level withAll: 0. 
	(version isNil or: [ version > 2 ]) ifTrue: [ 
		left := Array new: level withAll: 0. 
		1 to: level do: [ :n |
			left at: n put: (aStream next: self leftSize) asInteger ] ].
	1 to: level do: [ :n |
		right at: n put: (aStream next: self rightSize) asInteger ]
]

{ #category : #accessing }
SoilSkipListPage >> right [
	^ right
]

{ #category : #accessing }
SoilSkipListPage >> rightAt: anInteger [ 
	^ right at: anInteger 
]

{ #category : #accessing }
SoilSkipListPage >> rightAt: anInteger put: anObject [ 
	right at: anInteger put: anObject.
	needWrite := true
]

{ #category : #writing }
SoilSkipListPage >> rightSize [
	"this fixes the maximum number of pages to 32 bits which should be enough. This
	17TB when using a page size of 4k"
	^ 4
]

{ #category : #private }
SoilSkipListPage >> sizeInBytes [
	^ self headerSize + (items size * (self keySize + self valueSize))
]

{ #category : #private }
SoilSkipListPage >> split: newPage [
	| middle |
	middle := (items size / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	needWrite := true.
	^ newPage
	
]

{ #category : #accessing }
SoilSkipListPage >> valueSize [ 
	^ valueSize
]

{ #category : #accessing }
SoilSkipListPage >> valueSize: anInteger [ 
	valueSize := anInteger 
]

{ #category : #writing }
SoilSkipListPage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream nextPutAll: (lastTransaction asByteArrayOfSize: 8)

]

{ #category : #writing }
SoilSkipListPage >> writeLevelsOn: aStream [ 
	aStream 
		nextPut: self level.
	"for data pages version is nil and for header pages it is 
	bigger than 2"
	(version isNil or: [ version > 2 ]) ifTrue: [ 
		1 to: self level do: [ :n |
			aStream nextPutAll: ((left at: n) asByteArrayOfSize: self leftSize) ] ].
	1 to: self level do: [ :n |
		aStream nextPutAll: ((right at: n) asByteArrayOfSize: self rightSize) ]
]
