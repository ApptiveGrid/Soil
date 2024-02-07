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
