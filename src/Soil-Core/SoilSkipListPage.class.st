Class {
	#name : #SoilSkipListPage,
	#superclass : #SoilIndexPage,
	#instVars : [
		'right',
		'items',
		'keySize',
		'valueSize',
		'lastTransaction'
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
SoilSkipListPage class >> pageCode [
	"abstract"
	^ 0 
]

{ #category : #adding }
SoilSkipListPage >> addItem: anAssociation [ 
	items add: anAssociation.
	dirty := true
]

{ #category : #accessing }
SoilSkipListPage >> associationAt: anInteger [ 
	^ self 
		associationAt: anInteger 
		ifAbsent: nil
]

{ #category : #accessing }
SoilSkipListPage >> associationAt: key ifAbsent: aBlock [
	^ items 
		detect: [:each | each key = key ] 
		ifNone: aBlock
]

{ #category : #accessing }
SoilSkipListPage >> biggestKey [
	^ self isLastPage 
		ifTrue: [ (2 raisedTo: (keySize * 8)) - 1 ]
		ifFalse: [ self lastKey ]
]

{ #category : #accessing }
SoilSkipListPage >> firstItem [

	^ items isNotEmpty ifTrue: [ items first ]
]

{ #category : #testing }
SoilSkipListPage >> hasRoom [
	| used itemSize |
	itemSize := keySize + valueSize.
	used := self headerSize + (items size * itemSize).
	^ used <= (self pageSize - itemSize)
]

{ #category : #utilities }
SoilSkipListPage >> headerSize [
	^ super headerSize + 8 "last transaction number"
]

{ #category : #accessing }
SoilSkipListPage >> indexOfKey: anInteger [ 
	items withIndexDo: [ :each :idx |
		(each key = anInteger) ifTrue: [ ^ idx ] ].
	^ 0
	
		
]

{ #category : #initialization }
SoilSkipListPage >> initialize [ 
	super initialize.
	items := SortedCollection new.
	lastTransaction := 0.
	dirty := true.

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
SoilSkipListPage >> isEmpty [
	^ items isEmpty 
]

{ #category : #testing }
SoilSkipListPage >> isLastPage [
	^ (right at: 1) = 0
]

{ #category : #testing }
SoilSkipListPage >> isOlderThan: aVersionNumber [ 
	^ lastTransaction <= aVersionNumber 
]

{ #category : #accessing }
SoilSkipListPage >> itemAfter: key [ 
	| i item |
	i := items findBinaryIndex: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	(i = items size) ifTrue: [ ^ nil].
	item := items at: i + 1.
	^ item
]

{ #category : #accessing }
SoilSkipListPage >> itemAt: anInteger ifAbsent: aBlock [
	^ items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | items at: ind ]
		ifNone: aBlock 
]

{ #category : #accessing }
SoilSkipListPage >> itemAt: key put: anObject [ 
	| removedItem |
	removedItem := self itemRemoveAt: key ifAbsent: [ KeyNotFound signal: 'this method is just for replacing items'].
	items add: (key -> anObject).
	dirty := true.
	^ removedItem
]

{ #category : #accessing }
SoilSkipListPage >> itemBefore: key [

	| item |
	item := items findBinary: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	^ items before: item ifAbsent: nil
]

{ #category : #accessing }
SoilSkipListPage >> itemCapacity [
	^ ((self pageSize - self headerSize) / (self keySize + self valueSize)) floor
]

{ #category : #accessing }
SoilSkipListPage >> itemRemoveAt: key [ 
	^ self 
		itemRemoveAt: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilSkipListPage >> itemRemoveAt: anInteger ifAbsent: aBlock [
	| item |
	items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | item := items removeAt: ind ]
		ifNone: [ ^ aBlock value ].
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilSkipListPage >> itemRemoveIndex: anInteger [
	| item |
	item := items at: anInteger.
	items removeAt: anInteger.
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilSkipListPage >> items [
	^ items
]

{ #category : #accessing }
SoilSkipListPage >> keyOrClosestAfter: key [ 
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
SoilSkipListPage >> keySize [ 
	^ keySize
]

{ #category : #accessing }
SoilSkipListPage >> keySize: anInteger [ 
	(anInteger = 0) ifTrue: [ Error signal: 'cannot use key size 0' ].
	keySize := anInteger.
]

{ #category : #accessing }
SoilSkipListPage >> lastItem [

	^ items isNotEmpty ifTrue: [ items last ]
]

{ #category : #accessing }
SoilSkipListPage >> lastKey [

	^ items isNotEmpty ifTrue: [ items last key ]
]

{ #category : #accessing }
SoilSkipListPage >> lastTransaction [
	^ lastTransaction
]

{ #category : #accessing }
SoilSkipListPage >> lastTransaction: anInteger [ 
	lastTransaction := anInteger
]

{ #category : #accessing }
SoilSkipListPage >> level [ 
	^ right size
]

{ #category : #accessing }
SoilSkipListPage >> next [
	^ self rightAt: 1
]

{ #category : #accessing }
SoilSkipListPage >> numberOfItems [
	^ items size 
]

{ #category : #copying }
SoilSkipListPage >> postCopy [ 
	super postCopy.
	items := items copy.
	right := right copy
]

{ #category : #'instance creation' }
SoilSkipListPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readLastTransactionFrom: aStream
]

{ #category : #writing }
SoilSkipListPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: ((aStream next: self keySize) asInteger -> (aStream next: self valueSize) asSoilObjectId) ]
]

{ #category : #writing }
SoilSkipListPage >> readLastTransactionFrom: aStream [ 
	lastTransaction := (aStream next: 8) asInteger.

]

{ #category : #writing }
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
	dirty := true
]

{ #category : #writing }
SoilSkipListPage >> rightSize [
	"this fixes the maximum number of pages to 32 bits which should be enough. This
	17TB when using a page size of 4k"
	^ 4
]

{ #category : #accessing }
SoilSkipListPage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #private }
SoilSkipListPage >> sizeInBytes [
	^ self headerSize + (items size * (self keySize + self valueSize))
]

{ #category : #accessing }
SoilSkipListPage >> smallestKey [
	^ items first key
]

{ #category : #private }
SoilSkipListPage >> split: newPage [
	| middle |
	middle := (items size / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	dirty := true.
	^ newPage
	
]

{ #category : #accessing }
SoilSkipListPage >> valueAt: anInteger [ 
	^ self 
		valueAt: anInteger 
		ifAbsent: nil
]

{ #category : #accessing }
SoilSkipListPage >> valueAt: anInteger ifAbsent: aBlock [
	^ (self 
		associationAt: anInteger
		ifAbsent: aBlock) value
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
SoilSkipListPage >> writeItemsOn: aStream [ 
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: self valueSize)].

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
