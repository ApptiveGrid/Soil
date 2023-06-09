Class {
	#name : #SoilSkipListIterator,
	#superclass : #SoilIndexIterator,
	#instVars : [
		'levels'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #private }
SoilSkipListIterator >> at: aKeyObject ifAbsent: aBlock [
	currentKey := (aKeyObject asSkipListKeyOfSize: index keySize) asInteger.
	self 
		findPageFor: currentKey 
		startingAt: index headerPage.
	^ currentPage 
		valueAt: currentKey
		ifAbsent: [ aBlock value ]
]

{ #category : #accessing }
SoilSkipListIterator >> at: aKeyObject put: anObject [
	| key  newPage itemIndex |
	key := (aKeyObject asSkipListKeyOfSize: index keySize) asInteger.
	self 
		findPageFor: key 
		startingAt: index headerPage.
	itemIndex := currentPage indexOfKey: key.
	"as an optimization we return the prior value stored in the list. If
	there was none we return nil"
	^ (itemIndex > 0)
		ifTrue: [ currentPage itemAt: key put: anObject ] 
		ifFalse: [ 
			currentPage hasRoom 
				ifTrue: [ currentPage addItem: (key -> anObject) ]
				ifFalse: [ 
					newPage := index splitPage: self forKey: key.
					((currentPage biggestKey < key)
						ifTrue: [ newPage ]
						ifFalse: [ currentPage ])
							addItem: (key -> anObject).
							nil ] ]
]

{ #category : #accessing }
SoilSkipListIterator >> atLevel: key put: anObject [
	levels at: key put: anObject 
]

{ #category : #private }
SoilSkipListIterator >> find: key [
	currentKey := key.
	self 
		findPageFor: key 
		startingAt: index headerPage.
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
				candidatePage smallestKey <= key ] ]
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
	| maxLevel pageNumber |
	maxLevel := "self index maxLevel."1.
	"there is a bug with right being 0 for pages other then the last"
	currentPage := index headerPage.
	[ (pageNumber := currentPage rightAt: maxLevel) isZero ] whileFalse: [ 
		currentPage := self pageAt: pageNumber ].
	^currentPage
]

{ #category : #accessing }
SoilSkipListIterator >> levelAt: anInteger [ 
	^ levels at: anInteger 
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
		currentPage := index store headerPage.
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
						currentPage := index store pageAt: (currentPage rightAt: 1).
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage firstItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #private }
SoilSkipListIterator >> nextKeyCloseTo: key [

	| binKey |
	binKey := (key asSkipListKeyOfSize: index keySize) asInteger.
	self findPageFor: binKey startingAt: index headerPage.
	nextKey := currentPage keyOrClosestAfter: binKey.
	nextKey
		ifNil: [ "if there is no close key found, we position the cursor at the end, so that asking for the next association will return nil" 
			currentKey := currentPage lastKey ]
		ifNotNil: [ 
			"if there is a close key found, we make sure the cursor get properly positioned"
			currentKey := nextKey ]
]

{ #category : #printing }
SoilSkipListIterator >> printOn: aStream [ 
	aStream << 'path: ' << levels asString
]

{ #category : #'as yet unclassified' }
SoilSkipListIterator >> updateCurrentTransaction: anInteger [ 
	currentPage lastTransaction: anInteger
]
