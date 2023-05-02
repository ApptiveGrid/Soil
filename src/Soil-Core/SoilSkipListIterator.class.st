Class {
	#name : #SoilSkipListIterator,
	#superclass : #Object,
	#instVars : [
		'skipList',
		'levels',
		'currentPage',
		'currentKey',
		'nextKey'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SoilSkipListIterator class >> on: aSoilSkipList [ 
	^ self new 
		skipList: aSoilSkipList 
]

{ #category : #accessing }
SoilSkipListIterator >> atLevel: key put: anObject [
	levels at: key put: anObject 
]

{ #category : #enumerating }
SoilSkipListIterator >> do: aBlock [
	| item |
	[ (item := self next) isNil ] whileFalse: [ 
		aBlock value: item ]
]

{ #category : #private }
SoilSkipListIterator >> find: key [
	currentKey := key.
	self 
		findPageFor: key 
		startingAt: skipList headerPage.
	^ currentPage valueAt: currentKey
]

{ #category : #private }
SoilSkipListIterator >> findPageFor: key startingAt: page [
	| pageIndex candidatePage |
	currentPage := page.
	levels size to: 1 by: -1 do: [ :level |
		[ 
			pageIndex := currentPage rightAt: level.
			(pageIndex > 0) and: [ 
				candidatePage := self pageAt: pageIndex.
				candidatePage smallestKey < key ] ]
					whileTrue: [ currentPage := candidatePage  ].
			self atLevel: level put: currentPage. ].
	^ currentPage 
]

{ #category : #accessing }
SoilSkipListIterator >> first [
	^ self firstAssociation ifNotNil: [ :assoc | assoc value ]
]

{ #category : #accessing }
SoilSkipListIterator >> firstAssociation [ 
	| item |
	currentPage := skipList store headerPage.
	item := currentPage firstItem.
	currentKey := item key.
	^ item
]

{ #category : #accessing }
SoilSkipListIterator >> lastAssociation [ 
	| item |
	currentPage := skipList store lastPage.
	item := currentPage lastItem.
	^ item
]

{ #category : #accessing }
SoilSkipListIterator >> lastPage [
	| maxLevel pageNumber |
	maxLevel := "self index maxLevel."1.
	"there is a bug with right being 0 for pages other then the last"
	currentPage := skipList headerPage.
	[ (pageNumber := currentPage rightAt: maxLevel) isZero ] whileFalse: [ 
		currentPage := self pageAt: pageNumber ].
	^currentPage
]

{ #category : #accessing }
SoilSkipListIterator >> levelAt: anInteger [ 
	^ levels at: anInteger 
]

{ #category : #accessing }
SoilSkipListIterator >> next [
	^ self nextAssociation ifNotNil: [ :assoc | assoc value ]
]

{ #category : #accessing }
SoilSkipListIterator >> nextAssociation [
	| item |
	"preliminary support for nextKey. This is useful when iterating via #next 
	in order not jump over the first search key. nextKey implies the currentPage
	is on the right spot"
	nextKey ifNotNil: [ 
		item := currentPage 
			itemAt: nextKey 
			ifAbsent: [ Error signal: 'shoulndt be possible' ].
		nextKey := nil.
		^ item ].
	currentPage ifNil: [ 
		currentPage := skipList store headerPage.
		currentKey := nil ].
	[ currentPage isNil ] whileFalse: [  
		item := currentKey 
			ifNotNil: [  
				(currentPage itemAfter: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						((currentPage right at: 1) = 0) ifTrue: [ ^ nil ].
						currentPage := skipList store pageAt: (currentPage rightAt: 1).
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage firstItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #private }
SoilSkipListIterator >> nextKeyCloseTo: key [
	self 
		findPageFor: key
		startingAt: skipList headerPage.
	nextKey := currentPage keyOrClosestAfter: key
]

{ #category : #accessing }
SoilSkipListIterator >> page [

	^ currentPage
]

{ #category : #accessing }
SoilSkipListIterator >> page: anObject [

	currentPage := anObject
]

{ #category : #private }
SoilSkipListIterator >> pageAt: anInteger [
	^ skipList store pageAt: anInteger
]

{ #category : #printing }
SoilSkipListIterator >> printOn: aStream [ 
	aStream << 'path: ' << levels asString
]

{ #category : #accessing }
SoilSkipListIterator >> size [
	"We iterate over all elements to get the size. Slow!"
	| sum |
	sum := 0.
	self do: [ :each | sum := sum + 1 ].
	^ sum
]

{ #category : #accessing }
SoilSkipListIterator >> skipList: aSoilSkipList [ 
	skipList := aSoilSkipList.
	levels := Array new: skipList maxLevel 
]
