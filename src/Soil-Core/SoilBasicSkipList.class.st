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
		ifAbsent: [ KeyNotFound signal: key ]
]

{ #category : #private }
SoilBasicSkipList >> at: anObject ifAbsent: aBlock [
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilBasicSkipList >> at: aKeyObject put: anObject [
	| key iterator page index newPage |
	key := (aKeyObject asSkipListKeyOfSize: self keySize) asInteger.
	iterator := self newIterator.
	iterator find: key.
	page := iterator page.
	index := page indexOfKey: key.
	"as an optimization we return the prior value stored in the list. If
	there was none we return nil"
	^ (index > 0)
		ifTrue: [ page itemAt: key put: anObject ] 
		ifFalse: [ 
			page hasRoom 
				ifTrue: [ iterator page addItem: (key -> anObject) ]
				ifFalse: [ 
					newPage := self splitPage: iterator.
					((page biggestKey < key)
						ifTrue: [ newPage ]
						ifFalse: [ page ])
							addItem: (key -> anObject).
							nil ] ]
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
SoilBasicSkipList >> firstItem [
	^ self headerPage firstItem
]

{ #category : #accessing }
SoilBasicSkipList >> firstPage [
	^ self store pageAt: 1
]

{ #category : #'as yet unclassified' }
SoilBasicSkipList >> headerPage [
	^ self store headerPage
]

{ #category : #testing }
SoilBasicSkipList >> isEmpty [
	^ self store headerPage hasItems not
]

{ #category : #'as yet unclassified' }
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
	^ self newIterator lastAssociation value
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

{ #category : #removing }
SoilBasicSkipList >> removeKey: key [ 
	^ self
		removeKey: key 
		ifAbsent: [ KeyNotFound signal: key ]
]

{ #category : #removing }
SoilBasicSkipList >> removeKey: aString ifAbsent: aBlock [
	| page index key |
	key := (aString asSkipListKeyOfSize: self keySize) asInteger.
	page := self newIterator 
		find: key;
		page.
	^ ((index := page indexOfKey: key) > 0) 
		ifTrue: [ (page itemRemoveIndex: index) value ]
		ifFalse: [ aBlock value ]
]

{ #category : #accessing }
SoilBasicSkipList >> size [
	"We iterate over all elements to get the size. Slow!"
	^ self newIterator size 
]

{ #category : #'as yet unclassified' }
SoilBasicSkipList >> splitPage: aIterator [ 
	| newPage page |
	page := aIterator page.
	newPage := page split: store newPage.
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
