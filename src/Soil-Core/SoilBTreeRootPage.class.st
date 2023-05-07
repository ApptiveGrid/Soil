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
	self addItem: 0 -> 1 "headPage id"
]

{ #category : #accessing }
SoilBTreeRootPage >> insert: anItem into: aBtree [
	| indexPage newPage indexItem newIndexPage1 newIndexPage2 |
		
	indexPage := self findPageFor: anItem key with: aBtree.
	indexPage ifNil: [ ^nil ]. "nothing to do"
	newPage := indexPage insert: anItem into: aBtree.
	newPage ifNil: [ ^nil ]. "nothing to do"
	
	indexItem := newPage smallestKey -> newPage index.
	"if the insert resulted in a split, we have to update the index, which might habe to split, too"
	self hasRoom ifTrue: [ self addItem: indexItem . ^ nil ].
	newIndexPage1 := aBtree splitIndexPage: self.
	"we are the root index page, thus we have to create another index page and move items there"
	newIndexPage2 := aBtree newIndexPageFromRoot: self.
	
	"here now add entries for newIndexPage1 and newIndexPage2 to self"
	self addItem: newIndexPage1 smallestKey -> newIndexPage1 index.
	self addItem: newIndexPage2 smallestKey -> newIndexPage2 index.
	
	"and add the indexItem to one of the two"
	((newIndexPage1 smallestKey <= anItem key) 
		ifTrue: [ newIndexPage1 ] 
		ifFalse: [ newIndexPage2 ]) addItem: indexItem.

	^nil
]

{ #category : #printing }
SoilBTreeRootPage >> printOn: aStream [ 
	aStream << 'root index page : #' << index asString
]
