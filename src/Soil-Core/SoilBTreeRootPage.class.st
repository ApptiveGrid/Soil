"
The BTree root page is always created and exists even in an empty BTree.

It is easily accessible via #rootPage on the BTree index
"
Class {
	#name : #SoilBTreeRootPage,
	#superclass : #SoilBTreeIndexPage,
	#category : #'Soil-Core-Index-BTree'
}

{ #category : #accessing }
SoilBTreeRootPage class >> pageCode [ 
	^ 6
]

{ #category : #initialization }
SoilBTreeRootPage >> initialize [
	super initialize.
	self addItem: 0 -> 1 "headPage id"
]

{ #category : #searching }
SoilBTreeRootPage >> insertItem: item for: iterator [
	| foundItem return newIndexPage1 newIndexPage2 |
	
	foundItem := self findKey: item key.

	return := (iterator index pageAt: foundItem value) insertItem: item for: iterator.
	return indexEntryNeeded ifFalse: [  ^ return ].
	"We need to add to this index page"
	
	self addItem: return indexEntry.
	self hasRoom ifTrue: [  ^ return indexEntry: nil].
	"No space, we have to split"

	"we are the root index page, thus we have to create another index page and move items there"
	newIndexPage1 := iterator index newIndexPageFromRoot: self.
	newIndexPage2 := iterator index splitIndexPage: newIndexPage1.
	
	"here now add entries for newIndexPage1 and newIndexPage2 to self"
	self addItem: newIndexPage1 smallestKey -> newIndexPage1 index.
	self addItem: newIndexPage2 smallestKey -> newIndexPage2 index.
	^ return
]

{ #category : #printing }
SoilBTreeRootPage >> printOn: aStream [ 
	aStream << 'root index page : #' << index asString
]
