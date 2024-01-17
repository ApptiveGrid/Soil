Class {
	#name : #SoilBTreePage,
	#superclass : #SoilIndexItemsPage,
	#instVars : [
		'keySize',
		'lastTransaction'
	],
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreePage class >> indexClass [ 
	^ SoilBTree 
]

{ #category : #testing }
SoilBTreePage class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBTreePage
]

{ #category : #adding }
SoilBTreePage >> addItem: anAssociation [
	"Updates entry if already there (different to SoilSkipListPage>>#addItem:)"
	(items anySatisfy: [ :item | item key = anAssociation key ])
		ifFalse: [ items add: anAssociation ]
		ifTrue:  [ self itemAt: anAssociation key put: anAssociation value ].
	dirty := true
]

{ #category : #private }
SoilBTreePage >> find: aKey with: aBTree [ 
	^ self subclassResponsibility
]

{ #category : #initialization }
SoilBTreePage >> initialize [ 
	super initialize.
	lastTransaction := 0.
	dirty := true
]

{ #category : #testing }
SoilBTreePage >> isOlderThan: aVersionNumber [ 
	^ lastTransaction <= aVersionNumber 
]

{ #category : #accessing }
SoilBTreePage >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilBTreePage >> keySize: anInteger [ 
	keySize := anInteger
]

{ #category : #accessing }
SoilBTreePage >> lastTransaction [
	^ lastTransaction
]

{ #category : #accessing }
SoilBTreePage >> lastTransaction: anInteger [ 
	lastTransaction := anInteger
]

{ #category : #accessing }
SoilBTreePage >> pointerSize [
	"this is the size in bytes used to point to other pages"
	^ 4
]

{ #category : #reading }
SoilBTreePage >> readFrom: aStream [ 
	super readFrom: aStream.
	self readLastTransactionFrom: aStream
]

{ #category : #reading }
SoilBTreePage >> readItemsFrom: aStream [ 
	| numberOfItems |
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	items := SortedCollection new: numberOfItems.
	numberOfItems timesRepeat: [ 
		items add: (aStream next: self keySize) asInteger -> (aStream next: self valueSize) ]
]

{ #category : #writing }
SoilBTreePage >> readLastTransactionFrom: aStream [ 
	lastTransaction := (aStream next: 8) asInteger.
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
SoilBTreePage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream nextPutAll: (lastTransaction asByteArrayOfSize: 8)
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

{ #category : #writing }
SoilBTreePage >> writeOn: aStream [ 
	super writeOn: aStream.
	self writeItemsOn: aStream
]
