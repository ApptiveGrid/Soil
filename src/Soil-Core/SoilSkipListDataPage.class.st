Class {
	#name : #SoilSkipListDataPage,
	#superclass : #SoilSkipListPage,
	#instVars : [
		'right',
		'items',
		'keySize',
		'valueSize'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #testing }
SoilSkipListDataPage class >> isAbstract [ 
	^ self == SoilSkipListDataPage 
]

{ #category : #adding }
SoilSkipListDataPage >> addItem: anAssociation [ 
	items add: anAssociation.
	dirty := true
]

{ #category : #accessing }
SoilSkipListDataPage >> associationAt: anInteger [ 
	^ items 
		detect: [:each | each key = anInteger ] 
		ifNone: [ nil ]
]

{ #category : #'as yet unclassified' }
SoilSkipListDataPage >> biggestKey [
	^ items last key
]

{ #category : #accessing }
SoilSkipListDataPage >> firstItem [
	| item |
	self flag: #todo.
	"bad way of determine the first item. Here we filter out the lower and
	upper element"
	item := items first.
	^ (item key = 0)
		ifTrue: [ 
			(items second value = 0)
				ifTrue: [ ^ nil ]
				ifFalse: [ items second ] ]
		ifFalse: [ item ]
	
]

{ #category : #testing }
SoilSkipListDataPage >> hasItems [
	self flag: #todo.
	"need to filter lowest and highest key and check for zero"
	^ items size > 2
]

{ #category : #testing }
SoilSkipListDataPage >> hasRoom [
	^ self headerSize + ((items size + 1) * (keySize + valueSize)) <= self pageSize
]

{ #category : #utilities }
SoilSkipListDataPage >> headerSize [
	self subclassResponsibility 
]

{ #category : #accessing }
SoilSkipListDataPage >> indexOfKey: anInteger [ 
	items withIndexDo: [ :each :idx |
		(each key = anInteger) ifTrue: [ ^ idx ] ].
	^ 0
	
		
]

{ #category : #initialization }
SoilSkipListDataPage >> initialize [ 
	super initialize.
	items := SortedCollection new.
	dirty := true.

]

{ #category : #initialization }
SoilSkipListDataPage >> initializeLevel: anInteger [
	| promote level |
	level := 1. 
	promote := true.
	[ (level < anInteger) & (promote = true) ] whileTrue: [ 
		level := level + 1.
		promote := self class random next > 0.5 ].
	right := Array new: level withAll: 0. 
]

{ #category : #'as yet unclassified' }
SoilSkipListDataPage >> itemAfter: key [ 
	| i item |
	i := items findBinaryIndex: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	(i = items size) ifTrue: [ ^ nil].
	item := items at: i + 1.
	(item key >= ((2 raisedTo: 64) - 1)) ifTrue: [ ^ nil ].
	^ item
]

{ #category : #accessing }
SoilSkipListDataPage >> itemAt: anInteger put: anObject [ 
	items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | items removeAt: ind ]
		ifNone: [ 0 ].
	items add: (anInteger -> anObject).
	dirty := true
]

{ #category : #'as yet unclassified' }
SoilSkipListDataPage >> itemCapacity [
	^ ((self pageSize - self headerSize) / (self keySize + self valueSize)) floor
]

{ #category : #accessing }
SoilSkipListDataPage >> items [
	^ items
]

{ #category : #writing }
SoilSkipListDataPage >> itemsSizeSize [
	^ 2
]

{ #category : #accessing }
SoilSkipListDataPage >> keySize [ 
	^ keySize
]

{ #category : #accessing }
SoilSkipListDataPage >> keySize: anInteger [ 
	(anInteger = 0) ifTrue: [ Error signal: 'cannot use key size 0' ].
	keySize := anInteger.
]

{ #category : #accessing }
SoilSkipListDataPage >> lastItem [
	| item maxKey |
	maxKey := (2 raisedTo: (keySize * 8)) - 1. 
	item := items last.
	^ (item key = maxKey)
		ifTrue: [ items at: items size - 1 ]
		ifFalse: [ item ] 
	
]

{ #category : #accessing }
SoilSkipListDataPage >> level [ 
	^ right size
]

{ #category : #accessing }
SoilSkipListDataPage >> level: anInteger [ 
	right := Array new: anInteger withAll: 0
]

{ #category : #accessing }
SoilSkipListDataPage >> numberOfItems [
	^ items size 
]

{ #category : #writing }
SoilSkipListDataPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: ((aStream next: self keySize) asInteger -> (aStream next: self valueSize)) ]
]

{ #category : #writing }
SoilSkipListDataPage >> readLevelsFrom: aStream [ 
	| level |
	level := aStream next asInteger.
	right := Array new: level. 
	1 to: level do: [ :n |
		right at: n put: (aStream next: self rightSize) asInteger ]
]

{ #category : #accessing }
SoilSkipListDataPage >> right [
	^ right
]

{ #category : #accessing }
SoilSkipListDataPage >> rightAt: anInteger [ 
	(anInteger > self level) ifTrue: [ ^ 0 ]. 
	^ self right at: anInteger 
]

{ #category : #accessing }
SoilSkipListDataPage >> rightAt: anInteger put: anObject [ 
	self right at: anInteger put: anObject
]

{ #category : #writing }
SoilSkipListDataPage >> rightSize [
	^ 4
]

{ #category : #accessing }
SoilSkipListDataPage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #accessing }
SoilSkipListDataPage >> setRight: aCollection [ 
	right := aCollection 
]

{ #category : #'as yet unclassified' }
SoilSkipListDataPage >> smallestKey [
	^ items first key
]

{ #category : #'as yet unclassified' }
SoilSkipListDataPage >> split [
	| newPage middle |
	newPage := self collection newPage.
	newPage 
		index: index.
	middle := (items size / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	^ newPage
	
]

{ #category : #'as yet unclassified' }
SoilSkipListDataPage >> split: newPage [
	| middle |
	newPage 
		index: index.
	middle := (items size / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	^ newPage
	
]

{ #category : #accessing }
SoilSkipListDataPage >> valueAt: anInteger [ 
	^ (self associationAt: anInteger) value
]

{ #category : #accessing }
SoilSkipListDataPage >> valueSize [ 
	^ valueSize
]

{ #category : #accessing }
SoilSkipListDataPage >> valueSize: anInteger [ 
	valueSize := anInteger 
]

{ #category : #writing }
SoilSkipListDataPage >> writeItemsOn: aStream [ 
	aStream
		nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: self valueSize)].

]

{ #category : #writing }
SoilSkipListDataPage >> writeLevelsOn: aStream [ 
	aStream 
		nextPut: self level.
	1 to: self level do: [ :n |
		aStream nextPutAll: ((right at: n) asByteArrayOfSize: self rightSize) ]
]
