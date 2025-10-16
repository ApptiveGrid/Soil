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

{ #category : #adding }
SoilSkipListPage >> addItem: anAssociation [

	| index |
	needWrite := true.

	items 
		findBinaryIndex: [ :each | anAssociation key - each key ] 
		do: [:idx | | removedItem |
			"replace the found index with the new value and return 
			the removed value"
			index := idx.
			[ index < items size and: [ (items at: index + 1) key = anAssociation key ] ] whileTrue: [ 
				index := index + 1 ].
			items add: anAssociation afterIndex: index.
			"removedItem := items at: index.
			items at: index put: anAssociation."
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
		do: [:ind | 	| removedItem |
			removedItem := items at: ind.
			items at: ind put: (key -> anObject).
			needWrite := true.
			^ removedItem ]
		ifNone: [ KeyNotFound signal: 'this method is just for replacing items' ].

]

{ #category : #accessing }
SoilSkipListPage >> itemIndexForKey: key [ 
	| index prevIndex |
	index := items 
		findBinaryIndex: [ :each | key - each key ] 
		do: [ :idx |  ^ idx ] 
		ifNone: [ ^ 0 ].
	"we are at a position where the key is present but we want to
	resolve the first key occurrence so we scan left"
	prevIndex := index.
	[ prevIndex > 1 ] whileTrue: [ 
		((items at: prevIndex - 1) key = key) ifFalse: [ ^ prevIndex ].
		prevIndex := prevIndex - 1.
  ].
	^ 0 
]

{ #category : #accessing }
SoilSkipListPage >> itemIndexForKey: key value: anObject [  
	| index prevIndex nextIndex |
	index := items 
		findBinaryIndex: [ :each | key - each key ] 
		do: [ :idx | 
			"now that we've found the key let's check if the value does
			match as well"
			((items at: idx) value = anObject) 
				ifTrue: [ ^ idx ].
			idx] 
		ifNone: [ ^ 0 ].
	"we've found the key but not anObject as value. We scan backward to find 
	all keys that are the same to find anObject"
	prevIndex := index.
	[ prevIndex > 1 and: [ (items at: prevIndex - 1) key = key] ] whileTrue: [ 
		prevIndex := prevIndex - 1.
		((items at: prevIndex) value = anObject) ifTrue: [ 
			^ prevIndex ] ].
	"backward scanning didn't help so we scan forward to find the same key in 
	the other direction still looking for anObject"
	nextIndex := index.
	[ nextIndex <= items size and: [ (items at: nextIndex) key = key] ] whileTrue: [ 
		((items at: nextIndex) value = anObject) ifTrue: [ 
			^ nextIndex ] .
		nextIndex := nextIndex + 1 ].
		
	^ 0 
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
SoilSkipListPage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readLastTransactionFrom: aStream
]

{ #category : #reading }
SoilSkipListPage >> readLevelsFrom: aStream [ 
	| level |
	level := aStream next asInteger.
	right := Array new: level withAll: 0. 
	(version > 2) ifTrue: [ 
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
	(version > 2) ifTrue: [ 
		1 to: self level do: [ :n |
			aStream nextPutAll: ((left at: n) asByteArrayOfSize: self leftSize) ] ].
	1 to: self level do: [ :n |
		aStream nextPutAll: ((right at: n) asByteArrayOfSize: self rightSize) ]
]

{ #category : #writing }
SoilSkipListPage >> writeOn: aStream [ 
	super writeOn: aStream.
	self writeItemsOn: aStream
	
]
