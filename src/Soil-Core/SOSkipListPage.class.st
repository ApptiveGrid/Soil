Class {
	#name : #SOSkipListPage,
	#superclass : #SOIndexFilePage,
	#instVars : [
		'list',
		'items',
		'pageNumber'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SOSkipListPage class >> readFrom: aStream [ 
	^ self new 
		readFrom: aStream
]

{ #category : #adding }
SOSkipListPage >> addNode: aSkipNode [ 
	aSkipNode page: self.
	items do: [ :item |
		(item keyIsSmallerThan: aSkipNode key)
			ifFalse: [ 
				items add: aSkipNode before: item.
				^ aSkipNode ] ].
	items add: aSkipNode 
]

{ #category : #accessing }
SOSkipListPage >> firstItem [
	^ items first
]

{ #category : #'as yet unclassified' }
SOSkipListPage >> fitsKey: aByteArray [ 
	"(items first key asInteger < bkey ) ifFalse: [ ^ false ]."
	(items last key asInteger > aByteArray asInteger) ifFalse: [ ^ false ].
	^ true

	
]

{ #category : #testing }
SOSkipListPage >> hasRoom [
	^ items size < 64
]

{ #category : #initialization }
SOSkipListPage >> initialize [ 
	super initialize.
	items := OrderedCollection new
]

{ #category : #accessing }
SOSkipListPage >> itemAt: anInteger [ 
	^ items at: anInteger 
]

{ #category : #'as yet unclassified' }
SOSkipListPage >> itemIndexOf: aSkipNode [ 
	^ items indexOf: aSkipNode
]

{ #category : #accessing }
SOSkipListPage >> items [
	^ items
]

{ #category : #accessing }
SOSkipListPage >> items: aCollection [ 
	items := aCollection
]

{ #category : #'as yet unclassified' }
SOSkipListPage >> keyFor: aString [ 
	^ aString asByteArray asByteArrayOfSize: 8
]

{ #category : #accessing }
SOSkipListPage >> list: aPersistedSkipList [ 
	list := aPersistedSkipList
]

{ #category : #'reading - basic' }
SOSkipListPage >> nextLengthEncodedInteger: aStream [
	| value |
	value := aStream next.
	(value < 128) ifTrue: [ ^ value ].
	^ ((self nextLengthEncodedInteger: aStream) bitShift: 7) bitOr: (value bitAnd: 127)
]

{ #category : #'writing - basic' }
SOSkipListPage >> nextPutLengthEncodedInteger: anInteger on: aStream [
	"store length of integer encoded in a way that the presence of a
	most significant bit indicates that the next byte is part of
	the value"
	anInteger < 128 ifTrue: [ ^ aStream nextPut: anInteger ].
	aStream
		nextPut: ((anInteger bitAnd: 127) bitOr: 128).
	self nextPutLengthEncodedInteger: (anInteger bitShift: -7) on: aStream
]

{ #category : #accessing }
SOSkipListPage >> numberOfItems [
	^ items size
]

{ #category : #accessing }
SOSkipListPage >> pageNumber [
	^ pageNumber
]

{ #category : #accessing }
SOSkipListPage >> pageNumber: anInteger [ 
	pageNumber := anInteger 
]

{ #category : #accessing }
SOSkipListPage >> pageSize [
	^ list filePageSize
]

{ #category : #printing }
SOSkipListPage >> printOn: aStream [ 
	aStream << 'page : #' << pageNumber asString
]

{ #category : #'instance creation' }
SOSkipListPage >> readFrom: aStream [ 
	| numberOfItems node |
	numberOfItems := (aStream next: 2) asInteger.
	1 to: numberOfItems do: [ :n |
		node := self readNodeFrom: aStream.
		items add: node ]
]

{ #category : #'as yet unclassified' }
SOSkipListPage >> readNodeFrom: aStream [ 
	| node value |
	node := list newNode
		key: (aStream next: 8);
		value: (aStream next: 8).
	1 to: list maxLevel do: [ :n |
		value := self nextLengthEncodedInteger: aStream.
		node rightAt: n put: ((value = 0) 
			ifTrue: [ aStream next. nil ]
			ifFalse: [ 
				SOSkipListNodeProxy new
					pageNumber: value;
					pageIndex: (self nextLengthEncodedInteger: aStream) ]) ].
	^ node
		
		
]

{ #category : #removing }
SOSkipListPage >> removeLastNode [
	^ items removeLast
]

{ #category : #writing }
SOSkipListPage >> writeOn: aStream [ 
	| pagePosition |
	pagePosition := list positionOfPage: self.  
	aStream position: pagePosition.
	aStream nextPutAll: (items size asByteArrayOfSize: 2).
	items do: [ :item |
		aStream 
			nextPutAll: (item key asByteArrayOfSize: 8);
			nextPutAll: (item value asByteArray asByteArrayOfSize: 8).
		item levels do: [ :lvl | 
			lvl
				ifNotNil: [ 
					self nextPutLengthEncodedInteger: lvl pageNumber on: aStream.
					self nextPutLengthEncodedInteger: lvl pageIndex on: aStream ]
				ifNil: [ aStream nextPutAll: #[ 0 0 ] ] ] ].
		aStream flush.
	((aStream position - pagePosition) > self pageSize) ifTrue: [ self halt. ] 
]
