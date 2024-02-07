Class {
	#name : #SoilSkipListIterator,
	#superclass : #SoilIndexIterator,
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
SoilSkipListIterator >> basicAt: key put: anObject [

	|itemIndex |
	self findPageFor: key.
	itemIndex := currentPage indexOfKey: key.
	"as an optimization we return the prior value stored in the list. If
	there was none we return nil"
	^ itemIndex > 0
		  ifTrue: [ currentPage itemAt: key put: anObject ]
		  ifFalse: [
			  currentPage hasRoom ifFalse: [  | newPage |
				  newPage := index splitPage: self forKey: key.
				  currentPage := currentPage biggestKey < key
					                 ifTrue: [ newPage ]
					                 ifFalse: [ currentPage ] ].
			  currentPage addItem: key -> anObject.
			  nil ]
]

{ #category : #private }
SoilSkipListIterator >> findPageFor: binKey [
	| pageIndex candidatePage |
	currentPage := index headerPage.
	levels size to: 1 by: -1 do: [ :level |
		[ 
			pageIndex := currentPage rightAt: level.
			(pageIndex > 0) and: [ 
				candidatePage := self pageAt: pageIndex.
				candidatePage smallestKey <= binKey ] ]
					whileTrue: [ currentPage := candidatePage  ].
			self atLevel: level put: currentPage. ].
	^ currentPage 
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
