Class {
	#name : #SoilSkipList,
	#superclass : #Object,
	#instVars : [
		'path',
		'pageRegistry'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #private }
SoilSkipList >> at: aByteArray [ 
	^ self 
		at: aByteArray 
		ifAbsent: [ Error signal: 'no found' ]
]

{ #category : #private }
SoilSkipList >> at: anObject ifAbsent: aBlock [
	path ifNil: [ aBlock value ].
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilSkipList >> at: aKeyObject put: anObject [
	| key iterator page index newPage |
	key := (aKeyObject asSkipListKeyOfSize: self keySize) asInteger.
	iterator := self iterator.
	iterator find: key.
	page := iterator page.
	index := page indexOfKey: key.
	(index > 0)
		ifTrue: [ page itemAt: key put: anObject ] 
		ifFalse: [ 
			page hasRoom 
				ifTrue: [ iterator page addItem: (key -> anObject) ]
				ifFalse: [ 
					newPage := self pageRegistry splitPage: iterator.
					((page biggestKey < key)
						ifTrue: [ newPage ]
						ifFalse: [ page ])
							addItem: (key -> anObject) ] ].
	^ anObject
]

{ #category : #accessing }
SoilSkipList >> atIndex: anInteger [ 
	| current iterator |
	iterator := self iterator.
	current := iterator first.
	2 to: anInteger do: [ :idx |
		current := iterator next ].
	^ current value
]

{ #category : #'initialize-release' }
SoilSkipList >> close [
	self pageRegistry close
]

{ #category : #deleting }
SoilSkipList >> destroy [
	path ensureDelete 
]

{ #category : #enumerating }
SoilSkipList >> do: aBlock [
	path ifNotNil: [ 
		self iterator do: aBlock ]
]

{ #category : #private }
SoilSkipList >> find: aString [ 
	^ self iterator 
		find: (aString asSkipListKeyOfSize: self keySize) asInteger
]

{ #category : #accessing }
SoilSkipList >> first: anInteger [ 
	| iterator col |
	iterator := self iterator.
	col := OrderedCollection new.
	anInteger timesRepeat: [ 
		(iterator next)
			ifNotNil: [ :value | col add: value ]
			ifNil: [ ^ col ]].
	^ col
]

{ #category : #accessing }
SoilSkipList >> firstItem [
	^ self startPage firstItem
]

{ #category : #accessing }
SoilSkipList >> firstPage [
	^ self pageRegistry pageAt: 1
]

{ #category : #accessing }
SoilSkipList >> flush [
	self pageRegistry flush
]

{ #category : #'as yet unclassified' }
SoilSkipList >> headerPage [
	^ self pageRegistry headerPage
]

{ #category : #initialization }
SoilSkipList >> initializeFilesystem [ 
	self pageRegistry 
		initializeFilesystem
]

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self pageRegistry initializeHeaderPage
]

{ #category : #testing }
SoilSkipList >> isEmpty [
	^ self pageRegistry startPage hasItems
]

{ #category : #'public/accessing' }
SoilSkipList >> iterator [ 
	^ SoilSkipListIterator on: self 
]

{ #category : #accessing }
SoilSkipList >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilSkipList >> keySize: anObject [

	self headerPage keySize: anObject
]

{ #category : #accessing }
SoilSkipList >> last [
	^ self pageRegistry lastPage lastItem
]

{ #category : #accessing }
SoilSkipList >> lastPage [
	self shouldBeImplemented.
]

{ #category : #actions }
SoilSkipList >> load [
	self readPageAt: 1
]

{ #category : #accessing }
SoilSkipList >> maxLevel [
	"^ maxLevel"
	^ self headerPage maxLevel
]

{ #category : #accessing }
SoilSkipList >> maxLevel: anInteger [ 
	"maxLevel := anInteger "
	self headerPage maxLevel: anInteger 
]

{ #category : #'instance creation' }
SoilSkipList >> newPage [
	^ SoilSkipListPage new 
		initializeLevel: self maxLevel;
		keySize: self keySize;
		valueSize: self valueSize;
		size: self pageSize;
		yourself
]

{ #category : #opening }
SoilSkipList >> open [
	self pageRegistry open
]

{ #category : #accessing }
SoilSkipList >> pageAt: anInteger [ 
	^ self pageRegistry pageAt: anInteger 
]

{ #category : #accessing }
SoilSkipList >> pageRegistry [
	^ pageRegistry ifNil: [ 
		pageRegistry := SoilPageRegistry new
			skipList: self ]
]

{ #category : #accessing }
SoilSkipList >> pageSize [
	^ 4 * 1024
]

{ #category : #accessing }
SoilSkipList >> pages [
	^ self pageRegistry pages
]

{ #category : #accessing }
SoilSkipList >> path [

	^ path
]

{ #category : #accessing }
SoilSkipList >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #accessing }
SoilSkipList >> size [ 
	^ self pageRegistry allItems size - 2
]

{ #category : #'as yet unclassified' }
SoilSkipList >> startPage [
	^ self pageRegistry startPage
]

{ #category : #accessing }
SoilSkipList >> valueSize [
	"^ 8"
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilSkipList >> valueSize: anInteger [ 
	"valueSize := anInteger"
	self headerPage valueSize: anInteger 
]

{ #category : #writing }
SoilSkipList >> writeHeaderPage [
	self pageRegistry writeHeaderPage
]

{ #category : #writing }
SoilSkipList >> writePages [
	self pageRegistry flushPages
]
