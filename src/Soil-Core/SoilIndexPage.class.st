Class {
	#name : #SoilIndexPage,
	#superclass : #Object,
	#instVars : [
		'index',
		'dirty',
		'pageSize',
		'items',
		'keySize'
	],
	#classInstVars : [
		'random'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilIndexPage class >> pageCode [ 
	self subclassResponsibility 
]

{ #category : #accessing }
SoilIndexPage class >> random [
	^ random ifNil: [ 
		random := Random seed: Time microsecondClockValue. ]
]

{ #category : #'instance creation' }
SoilIndexPage class >> readPageFrom: aStream keySize: keySize valueSize: valueSize [
	| pageCode pageClass page |
	pageCode := aStream next asInteger.
	pageClass := self allSubclasses detect: [ :class | class pageCode = pageCode ].
	page := pageClass new.
	page keySize: keySize.
	page valueSize: valueSize.
	^page readFrom: aStream.
]

{ #category : #adding }
SoilIndexPage >> addItem: anAssociation [ 
	items add: anAssociation.
	dirty := true
]

{ #category : #accessing }
SoilIndexPage >> associationAt: anInteger [ 
	^ self
		associationAt: anInteger 
		ifAbsent: [ nil ]
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> associationAt: anInteger ifAbsent: aBlock [
	^ items 
		detect: [:each | each key = anInteger ] 
		ifNone: [ aBlock value ]
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> biggestKey [
	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> firstItem [
	^ items first
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> hasRoom [
	^ self subclassResponsibility
]

{ #category : #utilities }
SoilIndexPage >> headerSize [ 
	^ 1 "pageCode" 
]

{ #category : #accessing }
SoilIndexPage >> index [
	^ index
]

{ #category : #accessing }
SoilIndexPage >> index: anInteger [ 
	index := anInteger
]

{ #category : #accessing }
SoilIndexPage >> indexOfKey: anInteger [ 
	items withIndexDo: [ :each :idx |
		(each key = anInteger) ifTrue: [ ^ idx ] ].
	^ 0
]

{ #category : #writing }
SoilIndexPage >> indexSize [
	^ 2
]

{ #category : #testing }
SoilIndexPage >> isDirty [
	^ dirty 
]

{ #category : #testing }
SoilIndexPage >> isEmpty [
	^ items isEmpty 
]

{ #category : #testing }
SoilIndexPage >> isLastPage [
	self shouldBeImplemented.
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> itemAfter: key [ 
	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> itemCapacity [
	^ ((self pageSize - self headerSize) / (self keySize + self valueSize)) floor
]

{ #category : #accessing }
SoilIndexPage >> itemRemoveAt: key [ 
	^ self 
		itemRemoveAt: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilIndexPage >> itemRemoveAt: anInteger ifAbsent: aBlock [
	| item |
	items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | item := items removeAt: ind ]
		ifNone: [ ^ aBlock value ].
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilIndexPage >> itemRemoveIndex: anInteger [
	| item |
	item := items at: anInteger.
	items removeAt: anInteger.
	dirty := true.
	^ item
]

{ #category : #accessing }
SoilIndexPage >> items [
	^ items
]

{ #category : #writing }
SoilIndexPage >> itemsSizeSize [
	"as long as we target 65536 bytes as maximum page size a two-byte 
	number of items is sufficient"
	^ 2
]

{ #category : #accessing }
SoilIndexPage >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilIndexPage >> keySize: anInteger [ 
	(anInteger = 0) ifTrue: [ Error signal: 'cannot use key size 0' ].
	keySize := anInteger.
]

{ #category : #accessing }
SoilIndexPage >> numberOfItems [
	^ items size
]

{ #category : #accessing }
SoilIndexPage >> pageSize [
	^ pageSize
]

{ #category : #accessing }
SoilIndexPage >> pageSize: anInteger [ 
	pageSize := anInteger 
]

{ #category : #printing }
SoilIndexPage >> printOn: aStream [ 
	aStream << 'page : #' << index asString
]

{ #category : #writing }
SoilIndexPage >> readFrom: aStream [ 
	dirty := false.
	"we do not read the pageCode here as it was read already"
]

{ #category : #writing }
SoilIndexPage >> readIndexFrom: aStream [ 
	self flag: #todo.
	"index should be determined at read time depending on the stream.
	we let the dummy read here for compatibility"
	"index :=" (aStream next: self indexSize) asInteger.

]

{ #category : #accessing }
SoilIndexPage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #accessing }
SoilIndexPage >> smallestKey [
	^ items first key
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> valueAt: anInteger [ 
	^ self 
		valueAt: anInteger 
		ifAbsent: [ nil ]
]

{ #category : #'as yet unclassified' }
SoilIndexPage >> valueAt: key ifAbsent: aBlock [
	^ (self 
		associationAt: key
		ifAbsent: [ ^ aBlock value ]) value
]

{ #category : #writing }
SoilIndexPage >> writeHeaderOn: aStream [ 
	aStream
		nextPut: self class pageCode
]

{ #category : #writing }
SoilIndexPage >> writeOn: aStream [ 
	dirty := false.
	self writeHeaderOn: aStream
]
