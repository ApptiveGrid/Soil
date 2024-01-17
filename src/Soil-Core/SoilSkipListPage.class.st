Class {
	#name : #SoilSkipListPage,
	#superclass : #SoilIndexItemsPage,
	#instVars : [
		'right',
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

{ #category : #adding }
SoilSkipListPage >> addItem: anAssociation [
	"Note: this can only be called for new items, client has to check first and update if an entry for the key is already there, different to SoilBTreePage>>#addItem:"
	items add: anAssociation.
	dirty := true
]

{ #category : #accessing }
SoilSkipListPage >> biggestKey [
	^ self isLastPage 
		ifTrue: [ (2 raisedTo: (keySize * 8)) - 1 ]
		ifFalse: [ self lastKey ]
]

{ #category : #initialization }
SoilSkipListPage >> initialize [ 
	super initialize.
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
SoilSkipListPage >> isLastPage [
	^ (right at: 1) = 0
]

{ #category : #testing }
SoilSkipListPage >> isOlderThan: aVersionNumber [ 
	^ lastTransaction <= aVersionNumber 
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

{ #category : #copying }
SoilSkipListPage >> postCopy [ 
	super postCopy.
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
	dirty := true.
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
