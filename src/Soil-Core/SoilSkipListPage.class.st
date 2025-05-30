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

{ #category : #adding }
SoilSkipListPage >> addItem: anAssociation [

	needWrite := true.

	items 
		findBinaryIndex: [ :each |  anAssociation key - each key ] 
		do: [:index | | removedItem |
			"replace the found index with the new value and return 
			the removed value"
			removedItem := items at: index.
			items at: index put: anAssociation.
			^ removedItem ]
		ifNone: [ :lower :upper |
			"upper will be an index bigger than collection size if 
			the element needs to be appended"
			(upper > items size) ifTrue: [
				items addLast: anAssociation.
				^ nil ].
			"if lower is greater than zero than lower and upper are 
			valid indexes where we need to insert in between"
			(lower > 0) ifTrue: [ 
				items add: anAssociation afterIndex: lower.
				^ nil ].
			"lower will be zero if the element needs to be added to 
			the front of the page"
			items addFirst: anAssociation.
			^ nil ]
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
	needWrite := true.
	self flag: #hack.
	"this is a newly initialization for the skip list as long as the
	BTree code has not been adjusted"
	items := OrderedCollection new

]

{ #category : #initialization }
SoilSkipListPage >> initializeInIndex: aSoilSkipList [
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
SoilSkipListPage >> itemAt: key put: anObject [ 
	self flag: #todo.
	"this needs to be improved. For itemAt:put: we search twice for the index. This 
	is to keep the assumption about replacing items. The way this is enforced might 
	be a strategy object instead soonish"
	items 
		findBinaryIndex: [ :each |  key - each key ] 
		do: [:ind | ind ]
		ifNone: [ KeyNotFound signal: 'this method is just for replacing items' ].
	^ self addItem: key -> anObject 
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
SoilSkipListPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	"calculate the maximum number of items that can be stored in this
	page so we spend that amount removing the need for the collection 
	to grow"
	items := OrderedCollection new: self itemCapacity.
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	numberOfItems timesRepeat: [ 
		items add: ((aStream next: self keySize) asInteger -> (aStream next: self valueSize) ) ]
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
