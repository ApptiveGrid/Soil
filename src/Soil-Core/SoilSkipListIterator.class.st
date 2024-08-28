"
The SoilBTreeIterator implements the SoilIndexIterator for the SkipList index.

Try to avoid calling any method that is not implemented in SoilIndexIterator to be able to change easily to another index implementation.

To get an iterator, call #newIterator on the index when used stand-alone, if the index is used for a SoilIndexedDictionary,
use the #newIterator there to setup the iterator correctly.
"
Class {
	#name : #SoilSkipListIterator,
	#superclass : #SoilRestoringIndexIterator,
	#instVars : [
		'levels'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #skiplist }
SoilSkipListIterator >> atLevel: key put: anObject [
	levels at: key put: anObject 
]

{ #category : #accessing }
SoilSkipListIterator >> basicAt: indexKey put: anObject [

	self findPageFor: indexKey.

	"as an optimization we return the prior value stored in the list. If
	there was none we return nil"
	^(currentPage hasKey: indexKey)
		  ifTrue: [ 
			"overwriting a key does not change the size of an index"
			(currentPage itemAt: indexKey put: anObject) value ]
		  ifFalse: [
			  currentPage hasRoom ifFalse: [  | newPage |
				  newPage := index splitPage: self forKey: indexKey.
				  currentPage := currentPage biggestKey < indexKey
					                 ifTrue: [ newPage ]
					                 ifFalse: [ currentPage ] ].
			  currentPage addItem: indexKey -> anObject.
			  index increaseSize.
			  nil ]
]

{ #category : #private }
SoilSkipListIterator >> findPageFor: indexKey [
	| pageIndex candidatePage |
	currentPage := index headerPage.
	levels size to: 1 by: -1 do: [ :level |
		[ 
			pageIndex := currentPage rightAt: level.
			(pageIndex > 0) and: [ 
				candidatePage := self pageAt: pageIndex.
				candidatePage smallestKey <= indexKey ] ]
					whileTrue: [ currentPage := candidatePage  ].
			self atLevel: level put: currentPage. ].
	^ currentPage 
]

{ #category : #private }
SoilSkipListIterator >> findPreviousPageOf: aPage [
	aPage isHeaderPage ifTrue: [ ^nil ].
	aPage isEmpty ifTrue: [ ^super findPreviousPageOf: aPage ].
	
	"faster search not yet working"
	self flag: #TOOD.
	^ super findPreviousPageOf: aPage.

"	currentPage := index headerPage.
	levels size to: 1 by: -1 do: [ :level |
		[ 
			pageIndex := currentPage rightAt: level.
			(pageIndex > 0) and: [ 
				candidatePage := self pageAt: pageIndex.
				(candidatePage isLastPage not and: [ (self pageAt: (candidatePage next)) == aPage])]]
					whileTrue: [ currentPage := candidatePage  ].
			self atLevel: level put: currentPage. ].
		
	self assert: (self nextPage == aPage).
	
	^ currentPage "
]

{ #category : #accessing }
SoilSkipListIterator >> index: aSoilSkipList [ 
	super index: aSoilSkipList.
	levels := Array new: index maxLevel 
]

{ #category : #accessing }
SoilSkipListIterator >> lastPage [
	| level pageNumber |
	"we start searching at the hights possible speed lane"
	level := index maxLevel.
	"we start on page #1 that has a right array of size maxLevel"
	currentPage := index headerPage.
	[ level >= 1 ] whileTrue: [  
		"we scan right as long as we get right page indexes which are larger
		than zero"
		[ (pageNumber := currentPage rightAt: level) isZero ] whileFalse: [ 
			currentPage := self pageAt: pageNumber.
			"if we encounter the last page before reaching level 1 we can 
			short cut the scan"
			currentPage isLastPage ifTrue: [ ^ currentPage ] ].
		"scanning on the current level stopped, drop down one level to 
		continue"
		level := level - 1.
	].
	^	currentPage
]

{ #category : #skiplist }
SoilSkipListIterator >> levelAt: anInteger [ 
	^ levels at: anInteger 
]

{ #category : #printing }
SoilSkipListIterator >> printOn: aStream [ 
	aStream << 'path: ' << levels asString
]

{ #category : #accessing }
SoilSkipListIterator >> size [ 
	| headerPage |
	"size in the header page is only correct if the current transaction
	read version is bigger than the last modification of the page. If 
	the header page is newer than the current transaction we need to scan
	the index for the size"
	headerPage := index headerPage.
	^ (readVersion isNil or: [ headerPage lastTransaction > readVersion ]) 
		ifTrue: [ super size] 
		ifFalse: [ headerPage size  ]
]
