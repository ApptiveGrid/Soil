Class {
	#name : #SoilBasicSkipList,
	#superclass : #Object,
	#instVars : [
		'store'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #private }
SoilBasicSkipList >> at: key [ 
	^ self 
		at: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #private }
SoilBasicSkipList >> at: anObject ifAbsent: aBlock [
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilBasicSkipList >> at: aKeyObject put: anObject [
	self newIterator 
		at: aKeyObject 
		put: anObject.

]

{ #category : #accessing }
SoilBasicSkipList >> atIndex: anInteger [ 
	| current iterator |
	iterator := self newIterator.
	current := iterator first.
	2 to: anInteger do: [ :idx |
		current := iterator next ].
	^ current value
]

{ #category : #accessing }
SoilBasicSkipList >> basicAt: key put: anObject [
	^ self newIterator 
		basicAt: key 
		put: anObject 
]

{ #category : #enumerating }
SoilBasicSkipList >> do: aBlock [
	self newIterator do: aBlock
]

{ #category : #private }
SoilBasicSkipList >> find: aString [ 
	^ self newIterator 
		find: (aString asSkipListKeyOfSize: self keySize) asInteger
]

{ #category : #accessing }
SoilBasicSkipList >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilBasicSkipList >> first: anInteger [ 
	| iterator col |
	iterator := self newIterator.
	col := OrderedCollection new.
	anInteger timesRepeat: [ 
		(iterator next)
			ifNotNil: [ :value | col add: value ]
			ifNil: [ ^ col ]].
	^ col
]

{ #category : #accessing }
SoilBasicSkipList >> firstPage [
	^ self store pageAt: 1
]

{ #category : #accessing }
SoilBasicSkipList >> headerPage [
	^ self store headerPage
]

{ #category : #testing }
SoilBasicSkipList >> isEmpty [
	^ self store headerPage hasItems not
]

{ #category : #testing }
SoilBasicSkipList >> isRegistered [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilBasicSkipList >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilBasicSkipList >> keySize: anInteger [
	anInteger isZero ifTrue: [ Error signal: 'keySize cannot be zero yet' ].
	self headerPage keySize: anInteger
]

{ #category : #accessing }
SoilBasicSkipList >> last [
	^ self newIterator last
]

{ #category : #accessing }
SoilBasicSkipList >> lastPage [
	^ self newIterator lastPage
]

{ #category : #accessing }
SoilBasicSkipList >> maxLevel [

	^ self headerPage maxLevel
]

{ #category : #accessing }
SoilBasicSkipList >> maxLevel: anInteger [ 

	self headerPage maxLevel: anInteger 
]

{ #category : #'public/accessing' }
SoilBasicSkipList >> newIterator [ 
	^ SoilSkipListIterator on: self 
]

{ #category : #accessing }
SoilBasicSkipList >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
]

{ #category : #accessing }
SoilBasicSkipList >> pageSize [
	^ 4 * 1024
]

{ #category : #accessing }
SoilBasicSkipList >> pages [
	^ self store pages
]

{ #category : #removing }
SoilBasicSkipList >> removeKey: key [ 
	^ self
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilBasicSkipList >> removeKey: aString ifAbsent: aBlock [
	| page index key |
	key := (aString asSkipListKeyOfSize: self keySize) asInteger.
	page := self newIterator 
		find: key;
		currentPage.
	^ ((index := page indexOfKey: key) > 0) 
		ifTrue: [ (page itemRemoveIndex: index) value ]
		ifFalse: [ aBlock value ]
]

{ #category : #accessing }
SoilBasicSkipList >> size [
	"We iterate over all elements to get the size. Slow!"
	^ self newIterator size 
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

{ #category : #accessing }
SoilBasicSkipList >> store [
	^ store ifNil: [ 
		store := self newFileStore ]
]

{ #category : #accessing }
SoilBasicSkipList >> store: anObject [
	anObject index: self.
	store := anObject
]

{ #category : #converting }
SoilBasicSkipList >> thePersistentInstance [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilBasicSkipList >> valueSize [
	"^ 8"
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilBasicSkipList >> valueSize: anInteger [ 
	"valueSize := anInteger"
	self headerPage valueSize: anInteger 
]

{ #category : #enumerating }
SoilBasicSkipList >> values [ 
	| values |
	values := OrderedCollection new.
	self do: [ :each |
		values add: each value ].
	^ values
]
