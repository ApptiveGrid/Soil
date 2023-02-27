Class {
	#name : #SoilSkipListPage,
	#superclass : #Object,
	#instVars : [
		'items',
		'registry',
		'dirty',
		'right',
		'level',
		'index'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #adding }
SoilSkipListPage >> addItem: anAssociation [ 
	items add: anAssociation.
	dirty := true
]

{ #category : #'as yet unclassified' }
SoilSkipListPage >> beFirstPage [
	index := 1.
	right := Array new: 16.
	items 
		add: (SoilSkipListSentinel lower -> 0);
		add: (SoilSkipListSentinel upper -> 0)
]

{ #category : #'as yet unclassified' }
SoilSkipListPage >> biggestKey [
	^ items last key
]

{ #category : #testing }
SoilSkipListPage >> hasRoom [
	^ items size * 72 <= (4096 - 72)
]

{ #category : #accessing }
SoilSkipListPage >> index [
	^ index
]

{ #category : #accessing }
SoilSkipListPage >> index: anInteger [ 
	index := anInteger
]

{ #category : #initialization }
SoilSkipListPage >> initialize [ 
	super initialize.
	items := SortedCollection new.
	dirty := true.

]

{ #category : #initialization }
SoilSkipListPage >> initializeLevel [
	| promote |
	level := 1.
	promote := true.
	[ (level < registry maxLevel) & (promote = true) ] whileTrue: [ 
		level := level + 1.
		promote := registry random next > 0.5 ].
]

{ #category : #initialization }
SoilSkipListPage >> initializePageIndex [
	index := registry nextPageIndex
]

{ #category : #testing }
SoilSkipListPage >> isDirty [
	^ dirty 
]

{ #category : #accessing }
SoilSkipListPage >> items [
	^ items
]

{ #category : #accessing }
SoilSkipListPage >> level [
	^ level
]

{ #category : #accessing }
SoilSkipListPage >> level: anInteger [ 
	level := anInteger
]

{ #category : #accessing }
SoilSkipListPage >> numberOfItems [
	^ items size 
]

{ #category : #printing }
SoilSkipListPage >> printOn: aStream [ 
	aStream << 'page : #' << index asString
]

{ #category : #writing }
SoilSkipListPage >> readFrom: aStream [ 
	| size |
	dirty := false.
	index := (aStream next: 2) asInteger.
	level := aStream next asInteger.
	size := (aStream next: 2) asInteger.
	items := SortedCollection new: size.
	size timesRepeat: [ 
		items add: ((aStream next: 8) asInteger -> (aStream next: 8)) ]
]

{ #category : #accessing }
SoilSkipListPage >> registry: aSoilPageRegistry [ 
	registry := aSoilPageRegistry
]

{ #category : #accessing }
SoilSkipListPage >> right [
	^ right ifNil: [ 
		right := Array new: level ]
]

{ #category : #accessing }
SoilSkipListPage >> rightAt: anInteger [ 
	^ self right at: anInteger 
]

{ #category : #accessing }
SoilSkipListPage >> rightAt: anInteger put: anObject [ 
	('page ', index asString,' level ', anInteger asString ,' put ', anObject asString) apptiveEmit.
	"(anObject isKindOf: Number) 
		ifTrue: [ (anObject > pageIndex) ifFalse: [ self halt ] ]
		ifFalse: [ anObject notNil ifTrue: [ self halt ] ]. "
	self right at: anInteger put: anObject
]

{ #category : #accessing }
SoilSkipListPage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #'as yet unclassified' }
SoilSkipListPage >> smallestKey [
	^ items first key
]

{ #category : #'as yet unclassified' }
SoilSkipListPage >> split [
	| newPage middle |
	newPage := self class new.
	newPage 
		registry: registry.
	middle := (items size / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	^ newPage
	
]

{ #category : #accessing }
SoilSkipListPage >> valueAt: anInteger [ 
	^ items 
		detect: [:each | each key = anInteger ] 
		ifNone: [ nil ]
]

{ #category : #writing }
SoilSkipListPage >> writeOn: aStream [ 
	aStream 
		nextPutAll: (index asByteArrayOfSize: 2);
		nextPut: level;
		nextPutAll: (items size asByteArrayOfSize: 2).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: 8);
			nextPutAll: (assoc value asByteArrayOfSize: 8)].
	dirty := false
]
