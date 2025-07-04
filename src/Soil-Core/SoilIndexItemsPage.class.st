"
Abstract superclass for all index related pages that store items. Just a place for all shared code.
"
Class {
	#name : #SoilIndexItemsPage,
	#superclass : #SoilIndexPage,
	#instVars : [
		'items',
		'lastTransaction',
		'keySize'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilIndexItemsPage class >> indexClass [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilIndexItemsPage class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexItemsPage
]

{ #category : #adding }
SoilIndexItemsPage >> addItem: anAssociation [

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

{ #category : #converting }
SoilIndexItemsPage >> asSoilFreePage [
	^ SoilFreePage new 
		offset: offset;
		pageSize: pageSize;
		markDirty
]

{ #category : #accessing }
SoilIndexItemsPage >> associationAt: anInteger [ 
	^ self
		associationAt: anInteger 
		ifAbsent: nil
]

{ #category : #accessing }
SoilIndexItemsPage >> associationAt: anInteger ifAbsent: aBlock [
	^ items 
		findBinary: [ :each | anInteger - each key] 
		ifNone: [ aBlock value ].
]

{ #category : #testing }
SoilIndexItemsPage >> canBeRemoved [
	^ self presentItemCount isZero
]

{ #category : #removing }
SoilIndexItemsPage >> cleanRemovedIn: index [
	self subclassResponsibility
]

{ #category : #accessing }
SoilIndexItemsPage >> firstItem [

	^ items isNotEmpty ifTrue: [ items first ]
]

{ #category : #testing }
SoilIndexItemsPage >> hasKey: aKey [

	^ items anySatisfy: [ :each | each key = aKey ]
]

{ #category : #testing }
SoilIndexItemsPage >> hasRoom [
	| used itemSize |
	itemSize := self keySize + self valueSize.
	used := self headerSize + 2 "items size" +(items size * itemSize).
	^ used <= (self pageSize - itemSize)
]

{ #category : #utilities }
SoilIndexItemsPage >> headerSize [
	^ super headerSize + 8 "last transaction number"
]

{ #category : #accessing }
SoilIndexItemsPage >> indexOfKey: anInteger [ 
	items withIndexDo: [ :each :idx |
		(each key = anInteger) ifTrue: [ ^ idx ] ].
	^ 0
]

{ #category : #initialization }
SoilIndexItemsPage >> initialize [
	super initialize.
	items := OrderedCollection new
]

{ #category : #initialization }
SoilIndexItemsPage >> initializeInIndex: aSoilSkipList [
]

{ #category : #testing }
SoilIndexItemsPage >> isDirty [
	^ self needsWrite or: [ self needsCleanup ] 
]

{ #category : #testing }
SoilIndexItemsPage >> isEmpty [
	^ items isEmpty 
]

{ #category : #testing }
SoilIndexItemsPage >> isNotEmpty [
	^ items isNotEmpty
]

{ #category : #testing }
SoilIndexItemsPage >> isOlderThan: aVersionNumber [ 
	^ lastTransaction <= aVersionNumber 
]

{ #category : #accessing }
SoilIndexItemsPage >> itemAfter: key [ 
	| i item |
	i := items findBinaryIndex: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	(i = items size) ifTrue: [ ^ nil].
	item := items at: i + 1.
	^ item
]

{ #category : #accessing }
SoilIndexItemsPage >> itemAt: anInteger ifAbsent: aBlock [
	^ items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | items at: ind ]
		ifNone: aBlock 
]

{ #category : #accessing }
SoilIndexItemsPage >> itemAt: key put: anObject [ 
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
SoilIndexItemsPage >> itemBefore: key [

	| item |
	item := items findBinary: [ :each | key - each key] do: [ :e | e ] ifNone: [ ^ nil ] .
	^ items before: item ifAbsent: nil
]

{ #category : #accessing }
SoilIndexItemsPage >> itemCapacity [
	^ ((self pageSize - (self headerSize + 2 "items size" )) / (self keySize + self valueSize)) floor
]

{ #category : #accessing }
SoilIndexItemsPage >> itemRemoveAt: key [ 
	^ self 
		itemRemoveAt: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilIndexItemsPage >> itemRemoveAt: anInteger ifAbsent: aBlock [
	| item |
	items 
		findBinaryIndex: [ :each |  anInteger - each key ] 
		do: [:ind | item := items removeAt: ind ]
		ifNone: [ ^ aBlock value ].
	needWrite := true.
	^ item
]

{ #category : #accessing }
SoilIndexItemsPage >> itemRemoveIndex: anInteger [
	| item |
	item := items at: anInteger.
	items removeAt: anInteger.
	needWrite := true.
	^ item
]

{ #category : #accessing }
SoilIndexItemsPage >> items [
	^ items
]

{ #category : #accessing }
SoilIndexItemsPage >> keyOrClosestAfter: key [ 
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
SoilIndexItemsPage >> keySize [
	^ keySize
]

{ #category : #accessing }
SoilIndexItemsPage >> keySize: anInteger [ 
	(anInteger = 0) ifTrue: [ Error signal: 'cannot use key size 0' ].
	keySize := anInteger
]

{ #category : #accessing }
SoilIndexItemsPage >> label [ 
	^ 'items page'
]

{ #category : #accessing }
SoilIndexItemsPage >> lastItem [

	^ items isNotEmpty ifTrue: [ items last ] ifFalse: [ nil ]
]

{ #category : #accessing }
SoilIndexItemsPage >> lastKey [

	^ items isNotEmpty ifTrue: [ items last key ]
]

{ #category : #accessing }
SoilIndexItemsPage >> lastTransaction [
	^ lastTransaction
]

{ #category : #accessing }
SoilIndexItemsPage >> lastTransaction: anInteger [ 
	lastTransaction := anInteger
]

{ #category : #testing }
SoilIndexItemsPage >> needsCleanup [ 
	^ items size > self presentItemCount 
]

{ #category : #accessing }
SoilIndexItemsPage >> numberOfItems [
	^ items size
]

{ #category : #copying }
SoilIndexItemsPage >> postCopy [ 
	super postCopy.
	items := items copy.
]

{ #category : #utilities }
SoilIndexItemsPage >> presentItemCount [
	^ (items reject: [ :each | each value isRemoved ]) size 
]

{ #category : #reading }
SoilIndexItemsPage >> readItemsFrom: aStream [ 
	| numberOfItems |
	"calculate the maximum number of items that can be stored in this
	page so we spend that amount removing the need for the collection 
	to grow"
	items := OrderedCollection new: self itemCapacity.
	numberOfItems := (aStream next: self itemsSizeSize) asInteger.
	numberOfItems timesRepeat: [ 
		items add: ((aStream next: self keySize) asInteger -> (aStream next: self valueSize) ) ]
]

{ #category : #writing }
SoilIndexItemsPage >> readLastTransactionFrom: aStream [ 
	lastTransaction := (aStream next: 8) asInteger.

]

{ #category : #accessing }
SoilIndexItemsPage >> setItems: aCollection [ 
	items := aCollection
]

{ #category : #accessing }
SoilIndexItemsPage >> smallestKey [
	^ items first key
]

{ #category : #accessing }
SoilIndexItemsPage >> valueAt: anInteger [ 
	^ self 
		valueAt: anInteger 
		ifAbsent: nil 
]

{ #category : #accessing }
SoilIndexItemsPage >> valueAt: anInteger ifAbsent: aBlock [
	^ (self 
		associationAt: anInteger
		ifAbsent: aBlock) value
]

{ #category : #accessing }
SoilIndexItemsPage >> valueSize [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexItemsPage >> valueSize: anInteger [ 
	^ self subclassResponsibility
]

{ #category : #writing }
SoilIndexItemsPage >> writeItemsOn: aStream [ 
	aStream nextPutAll: (items size asByteArrayOfSize: self itemsSizeSize).
	items do: [ :assoc |
		aStream 
			nextPutAll: (assoc key asByteArrayOfSize: self keySize);
			nextPutAll: (assoc value asByteArrayOfSize: self valueSize)].

]
