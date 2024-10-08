"
Abstract superclass for the SoilSkipList index.

This class just contains shared code between the main SkiplList and the copy-on-write version.

See SoilSkipList for more information
"
Class {
	#name : #SoilBasicSkipList,
	#superclass : #SoilIndex,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #testing }
SoilBasicSkipList class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBasicSkipList
]

{ #category : #testing }
SoilBasicSkipList >> hasHeaderPage [
	^ store hasHeaderPage 
]

{ #category : #accessing }
SoilBasicSkipList >> maxLevel [

	^ self headerPage maxLevel
]

{ #category : #accessing }
SoilBasicSkipList >> maxLevel: anInteger [ 

	self headerPage maxLevel: anInteger 
]

{ #category : #'instance creation' }
SoilBasicSkipList >> newIterator [ 
	^ SoilSkipListIterator on: self 
]

{ #category : #removing }
SoilBasicSkipList >> removePage: aPage [
	| iterator previousPage seen page |
	(aPage index > 1) ifFalse: [ Error signal: 'cannot remove header page' ].
	"we use an iterator to scan pages on all levels that are just right
	before the page to remove"
	iterator := self newIterator. 
	previousPage := iterator findPreviousPageOf: aPage. 
	"on each level up to max level the iterator has a reference to a 
	page. We remember the pages processed in order not to process the
	same page multiple times"
	seen := Set new.	
	1 to: self maxLevel do: [ :level |
		page := iterator levelAt: level.
		(seen includes: page) ifFalse: [  
			seen add: page.
			1 to: page level do: [ :lvl |
				"each previous page's next pointer might point to the page 
				to be removed."
				((page rightAt: lvl) = aPage index) ifTrue: [ 
					"We overwrite the next pointer of the previous page with 
					the next pointer of the page to be removed"
					page rightAt: lvl put: (aPage rightAt: lvl).
					page markDirty ] ] ] ].
	"finally remove the page from the store"
	store removePageAt: aPage index.
	^ aPage 


]

{ #category : #accessing }
SoilBasicSkipList >> size [ 
	"if size is -1 the page has been converted from version 1 format and
	size is uninitialized. We scan the size in order to write it properly"
	| size |
	size := self headerPage size.
	^ (size = -1) 
		ifTrue: [ super size  ]
		ifFalse: [ size ]
]

{ #category : #private }
SoilBasicSkipList >> splitPage: aIterator forKey: aKey [
	| newPage page |
	page := aIterator currentPage.
	"if we are on the last page and the new key is bigger then the
	last key of the page we can append a page and add the new key
	there. If the key is in between or the page is not the last we
	split the page with each containing half of the items"
	newPage := (page isLastPage and: [ page lastKey < aKey ])
		ifTrue: [ store newPage ] 
		ifFalse: [ page split: store newPage ].
	newPage index: self store nextPageIndex.
	newPage level to: 1 by: -1  do: [ :level |
		(level > page level)
			ifTrue: [ 
				newPage rightAt: level put: ((aIterator levelAt: level) rightAt: level).
				(aIterator levelAt: level) rightAt: level put: newPage index ]
			ifFalse: [ 
				(page rightAt: level) ifNotNil: [ :r | 
					newPage rightAt: level put: r ].
				page rightAt: level put: newPage index ]].
	self store pageAt: newPage index put: newPage.
	^ newPage 
]
