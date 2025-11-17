"
Abstract superclass for all BTree related pages. Just a place for all shared code between all the btree related pages
"
Class {
	#name : #SoilBTreePage,
	#superclass : #SoilIndexItemsPage,
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

{ #category : #assertions }
SoilBTreePage >> bTreeAssertion [
	self assert: items isNotEmpty.
	self assert: self hasRoom.
	"each node has a maximum of M children and at least ceil(M/2) - 1 children"
	self assert: (self numberOfItems <= self itemCapacity).
	self assert:  self hasUnderflow not
]

{ #category : #removing }
SoilBTreePage >> cleanRemovedIn: index [
	(items select: [ :each | each value isRemoved ])
		do: [:removedItem | self remove: removedItem key for: index].
	needWrite := true
]

{ #category : #private }
SoilBTreePage >> find: aKey with: aBTree [ 
	^ self subclassResponsibility
]

{ #category : #private }
SoilBTreePage >> findItemBefore: aKey [
	"like #itemBefore:, but comparung #<= like #find:with:"
	| item |
	item := items
	 		reversed detect: [ :each |
	 			each key <= aKey].
	^ items before: item ifAbsent: nil
]

{ #category : #private }
SoilBTreePage >> findPreviousPage: aKey with: aBTree path: aPath [ 
	^ self subclassResponsibility
]

{ #category : #assertions }
SoilBTreePage >> hasUnderflow [
	^ self numberOfItems < ((self itemCapacity  / 2) ceiling - 1)
]

{ #category : #initialization }
SoilBTreePage >> initialize [ 
	super initialize.
	lastTransaction := 0.
	needWrite := true
]

{ #category : #adding }
SoilBTreePage >> insertItem: anItem for: iterator [ 
	^ self subclassResponsibility
]

{ #category : #testing }
SoilBTreePage >> isIndexPage [
 	^ self subclassResponsibility
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

{ #category : #removing }
SoilBTreePage >> remove: aKey for: aBTree [ 
	^ self subclassResponsibility
]

{ #category : #private }
SoilBTreePage >> split: newPage [
	| middle |
	
	middle := (items size - 1 / 2) ceiling.
	newPage setItems: (items copyFrom: middle + 1 to: items size).
	items removeLast: items size - middle.
	needWrite := true.
	^ newPage
]

{ #category : #writing }
SoilBTreePage >> writeHeaderOn: aStream [ 
	super writeHeaderOn: aStream.
	aStream nextPutAll: (lastTransaction asByteArrayOfSize: 8)
]

{ #category : #writing }
SoilBTreePage >> writeOn: aStream [ 
	super writeOn: aStream.
	self writeItemsOn: aStream
]
