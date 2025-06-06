"
A skiplist stores data in pages (of 4KB), which are all instances of the two subclasses of this class.

The data pages form a linked list and can be traversed fast in the direction of the next page.

There is a special subclass for the first page (the header).
"
Class {
	#name : #SoilSkipListPage,
	#superclass : #SoilIndexItemsPage,
	#instVars : [
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
	right := Array new: level withAll: 0. 
]

{ #category : #testing }
SoilSkipListPage >> isLastPage [
	^ (right at: 1) = 0
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
	right := right copy
]

{ #category : #reading }
SoilSkipListPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readLastTransactionFrom: aStream
]

{ #category : #reading }
SoilSkipListPage >> readLevelsFrom: aStream [ 
	| level |
	level := aStream next asInteger.
	right := Array new: level withAll: 0. 
	1 to: level do: [ :n |
		right at: n put: (aStream next: self rightSize) asInteger ]
]

{ #category : #accessing }
SoilSkipListPage >> right [
	^ right
]

{ #category : #accessing }
SoilSkipListPage >> rightAt: anInteger [ 
	(anInteger > self level) ifTrue: [ ^ 0 ]. 
	^ self right at: anInteger 
]

{ #category : #accessing }
SoilSkipListPage >> rightAt: anInteger put: anObject [ 
	self right at: anInteger put: anObject.
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
	1 to: self level do: [ :n |
		aStream nextPutAll: ((right at: n) asByteArrayOfSize: self rightSize) ]
]

{ #category : #writing }
SoilSkipListPage >> writeOn: aStream [ 
	super writeOn: aStream.
	self writeItemsOn: aStream
	
]
