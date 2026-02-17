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

{ #category : #removing }
SoilBasicSkipList >> basicRemoveKey: key ifAbsent: aBlock [
	"Warning: Low level remove. If the page is empty after, the index will not work anymore, as we need minimal one key for search to work.
	Caller has to remove the empty page!"
	
	| page index |
	self hasUniqueKeys ifFalse: [ ^ self removeKeyAll: key ifAbsent: aBlock ].
	
	page := self newIterator 
		find: key;
		currentPage.
	^ ((index := page indexOfKey: (self indexKey: key)) > 0)
		ifTrue: [ 
			self decreaseSize.
			(page itemRemoveIndex: index) value ]
		ifFalse: [ aBlock value ]
]

{ #category : #removing }
SoilBasicSkipList >> basicRemoveKey: key value: aValue ifAbsent: aBlock [
	"Warning: Low level remove. If the page is empty after, the index will not work anymore, as we need minimal one key for search to work. Caller has to remove the empty page!"
	| page keyIndex |
	
	page := self newIterator 
		find: key;
		currentPage.
	
	keyIndex := self hasUniqueKeys 
		ifTrue: [ page itemIndexForKey: key ] 
		ifFalse: [ page itemIndexForKey: key value: aValue ]. 

	
	^ keyIndex > 0
		ifTrue: [ 
			self decreaseSize.
			(page itemRemoveIndex: keyIndex) value ]
		ifFalse: [ aBlock value ]
]

{ #category : #testing }
SoilBasicSkipList >> hasHeaderPage [
	^ store hasHeaderPage 
]

{ #category : #testing }
SoilBasicSkipList >> isBTree [
	^ false
]

{ #category : #removing }
SoilBasicSkipList >> legacyRemovePage: aPage [
	| iterator seen previousPage |
	(aPage offset > 1) ifFalse: [ ^ aPage ].
	"we use an iterator to scan pages on all levels that are just right
	before the page to remove"
	iterator := self newIterator. 
	iterator findPreviousPageOf: aPage. 
	"on each level up to max level the iterator has a reference to a 
	page. We remember the pages processed in order not to process the
	same page multiple times"
	seen := Set new.	
	1 to: self maxLevel do: [ :level |
		previousPage := iterator levelAt: level.
		(seen includes: previousPage) ifFalse: [  
			seen add: previousPage.
			self addDirtyPage: previousPage.
			1 to: previousPage level do: [ :lvl |
				"each previous page's next pointer might point to the page 
				to be removed."
				((previousPage rightAt: lvl) = aPage offset) ifTrue: [ 
					"We overwrite the next pointer of the previous page with 
					the next pointer of the page to be removed"
					previousPage rightAt: lvl put: (aPage rightAt: lvl).
					previousPage markForWrite ] ] ] ].
	"finally remove the page from the store"
	store removePageAt: aPage offset.
	^ aPage 


]

{ #category : #accessing }
SoilBasicSkipList >> maxLevel [

	^ self headerPage maxLevel
]

{ #category : #accessing }
SoilBasicSkipList >> maxLevel: anInteger [ 

	self headerPage maxLevel: anInteger 
]

{ #category : #utilities }
SoilBasicSkipList >> newIndexEntryClass [
	^ SoilNewSkipListIndexEntry
]

{ #category : #'instance creation' }
SoilBasicSkipList >> newIterator [ 
	^ SoilSkipListIterator on: self 
]

{ #category : #'instance creation' }
SoilBasicSkipList >> newPage [
	^ self pageClass new 
		initializeLevel: self maxLevel;
		keySize: self keySize;
		valueSize: self valueSize;
		pageSize: self pageSize;
		yourself
]

{ #category : #'instance creation' }
SoilBasicSkipList >> pageClass [
	^ SoilSkipListDataPage
]

{ #category : #removing }
SoilBasicSkipList >> removePage: aPage [
	| previousPage  nextPage next |
	"only remove if not header page (> 1)"
	(aPage offset > 1) ifFalse: [ ^ aPage ].
	(aPage version < 3) ifTrue: [ ^ self legacyRemovePage: aPage ].

	"we only need to scan up to the level of aPage. Previous/next pages on 
	higher levels point to different pages"
	1 to: aPage level do: [ :level | 
		"the left pointer is always filled because we dont remove the header
		page (see guard above). Therefor at least the header page is always 
		present on the left side"
		previousPage := self pageAt: (aPage leftAt: level).
		"point right of previous page to the next page (right of current)"
		previousPage rightAt: level put: (aPage rightAt: level)  .
		self addDirtyPage: previousPage.
		previousPage markForWrite.

		"if we are on the last page the right value will be 0 because there
		is no next page"
		nextPage := ((next := aPage rightAt: level) > 0)
			ifTrue: [  self pageAt: next ]
			ifFalse: [ self headerPage ].
			"point left of next next page to the previous (left of current)"
		nextPage leftAt: level put: (aPage leftAt: level).
		self addDirtyPage: nextPage.
		nextPage markForWrite ].

	"finally no page should point to aPage so we can safely remove the page"
	store removePageAt: aPage offset.
	^ aPage

]

{ #category : #accessing }
SoilBasicSkipList >> size [ 
	"if size is -1 the page has been converted from version 1 format and
	size is uninitialized. We scan the size in order to write it properly"
	| size |
	size := self headerPage size.
	^ (size == -1) 
		ifTrue: [ super size  ]
		ifFalse: [ size ]
]

{ #category : #private }
SoilBasicSkipList >> splitPage: aIterator forKey: aKey [
	| newPage currentPage previousPage nextPageOffset nextPage |
	currentPage := aIterator currentPage.
	"if we are on the last page and the new key is bigger then the last key 
	of the page we can append a page and add the new key there. If the key 
	is in between or the page is not the last we split the page with each 
	containing half of the items"
	newPage := (currentPage isLastPage and: [ currentPage lastKey < aKey ])
		ifTrue: [ store allocatePage ] 
		ifFalse: [ currentPage split: store allocatePage ].
	"rewire backlinks and forward links..."
	newPage level to: 1 by: -1  do: [ :newLevel |
		"if the level of the new page is equal or smaller than the 
		current level then the current page is the previous page of 
		the new one.
		If the level is bigger than the page in the iterator on that
		level is the previous one as we got here over that"
		previousPage := (newLevel <= currentPage level)
			ifTrue: [ currentPage ]
			ifFalse: [ aIterator levelAt: newLevel ].
		
		"add forward link by inserting the new page between the previous
		page and the next. The right pointer of the previous page becomes
		the right pointer of the new page and the new page becomes the right
		pointer of the previous page"
		nextPageOffset := previousPage rightAt: newLevel.
		newPage rightAt: newLevel put: nextPageOffset.
		previousPage rightAt: newLevel put: newPage offset.

		(previousPage == currentPage) ifFalse: [ 
            self addDirtyPage: previousPage ].
		
		"add backlink by setting left pointer to the previous page. "
		newPage leftAt: newLevel put: previousPage offset.
		"to set the left pointer of the next page we need to get
		the page first. If right is 0 we would need to add the newPage
		to the tail sentinel which we didn't model. So we use the header
		page as holder of the tail sentinel array"
		nextPage := (nextPageOffset > 0)
			ifTrue: [ store pageAt: nextPageOffset ]
			ifFalse: [ store headerPage ].
		nextPage leftAt: newLevel put: newPage offset.
		self addDirtyPage: nextPage ].
	^ newPage 
]
