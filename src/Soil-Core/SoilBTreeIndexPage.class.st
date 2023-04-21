Class {
	#name : #SoilBTreeIndexPage,
	#superclass : #SoilBTreePage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #private }
SoilBTreeIndexPage >> find: aKey with: aBTree [
	| page |
	page := self findPageFor: aKey with: aBTree.
	^ page find: aKey with: aBTree
]

{ #category : #searching }
SoilBTreeIndexPage >> findPageFor: aKey with: aBTree [
	self flag: #TODO. 
	"iterate without creatihg the copy"
	self items reversed detect: [ :item | item key <= aKey  ] ifFound: [ :found | ^ aBTree pageAt: found value]
]

{ #category : #utilities }
SoilBTreeIndexPage >> headerSize [
	^ self indexSize
]

{ #category : #accessing }
SoilBTreeIndexPage >> insert: anItem into: aBtree [
	| newPage indexItem |
		
	newPage := (self findPageFor: anItem key with: aBtree) insert: anItem into: aBtree.
	newPage ifNil: [ ^nil ]. "nothing to do"
	
	indexItem := newPage smallestKey -> newPage index.
	"if the insert resulted in a split, we have to update the index, which might habe to split, too"
	self hasRoom ifTrue: [ self addItem: indexItem . ^ nil ].
	self halt. "untested"
	newPage := aBtree splitIndexPage: self.
	
	((self biggestKey < newPage smallestKey)
						ifTrue: [ newPage ]
						ifFalse: [ self ]) addItem: indexItem.
	^newPage
	
	
	
]
