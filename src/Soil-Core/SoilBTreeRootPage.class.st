Class {
	#name : #SoilBTreeRootPage,
	#superclass : #SoilBTreeIndexPage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #'as yet unclassified' }
SoilBTreeRootPage class >> pageCode [ 
	^ 6
]

{ #category : #initialization }
SoilBTreeRootPage >> initialize [
	super initialize.
	self addItem: 0 -> (1 asByteArrayOfSize: 2) "headPage id"
]

{ #category : #accessing }
SoilBTreeRootPage >> insert: anItem into: aBtree [
	| indexPage newPage indexItem newPage2 |
		
	indexPage := self findPageFor: anItem key with: aBtree.
	indexPage ifNil: [ ^nil ]. "nothing to do"
	newPage := indexPage insert: anItem into: aBtree.
	newPage ifNil: [ ^nil ]. "nothing to do"
	
	indexItem := newPage smallestKey -> (newPage index asByteArrayOfSize: 2).
	"if the insert resulted in a split, we have to update the index, which might habe to split, too"
	self hasRoom ifTrue: [ self addItem: indexItem . ^ nil ].
	newPage := aBtree splitIndexPage: self.
	"we are the root index page, thus we have to create another index page and move items there"
	newPage2 := aBtree newIndexPageFromRoot: self.
	
	"here now add entries for newPage2 and newPage to self"
	self addItem: indexItem.
	self addItem: newPage2 smallestKey -> (newPage2 index asByteArrayOfSize: 2).
	^nil
]
