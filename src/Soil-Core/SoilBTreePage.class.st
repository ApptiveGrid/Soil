Class {
	#name : #SoilBTreePage,
	#superclass : #SoilIndexPage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreePage class >> indexClass [ 
	^ SoilBTree 
]

{ #category : #accessing }
SoilBTreePage class >> pageCode [
	"abstract"
	^0
]

{ #category : #accessing }
SoilBTreePage >> biggestKey [
	^ items last key
]

{ #category : #'as yet unclassified' }
SoilBTreePage >> find: aKey with: aBTree [ 
	^ self subclassResponsibility
]

{ #category : #testing }
SoilBTreePage >> hasRoom [
	^ self headerSize + ((items size + 1) * (self keySize + self valueSize)) <= self pageSize
]

{ #category : #utilities }
SoilBTreePage >> headerSize [
	self subclassResponsibility
]

{ #category : #initialization }
SoilBTreePage >> initialize [ 
	super initialize.
	items := SortedCollection new.
	dirty := true
]

{ #category : #'as yet unclassified' }
SoilBTreePage >> insert: anItem into: aBtree [ 
	^ self subclassResponsibility
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
SoilBTreePage >> pointerSize [
	^ 2
]

{ #category : #reading }
SoilBTreePage >> readItemsFrom: aStream [ 
	| numberOfItems |
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: self valueSize) ]
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

{ #category : #writing }
SoilBTreePage >> writeItemsOn: aStream [ 
	aStream
		nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: self valueSize)]
]
