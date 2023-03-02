Class {
	#name : #SoilSkipList,
	#superclass : #Object,
	#instVars : [
		'maxLevel',
		'path',
		'keySize',
		'pageRegistry',
		'valueSize'
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
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilSkipList >> at: aKeyObject put: anObject [
	| key iterator page index newPage |
	key := (aKeyObject asSkipListKeyOfSize: self keySize) asInteger.
	iterator := self iteratorForKey: key.
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

{ #category : #'initialize-release' }
SoilSkipList >> close [
	self pageRegistry close
]

{ #category : #accessing }
SoilSkipList >> defaultKeySize [
	^ 16
]

{ #category : #deleting }
SoilSkipList >> destroy [
	path ensureDelete 
]

{ #category : #private }
SoilSkipList >> find: aString [ 
	| page key |
	key := (aString asSkipListKeyOfSize: self keySize) asInteger.
	page := self findPageCandidateFor: key.
	^ (page valueAt: key) value
]

{ #category : #'as yet unclassified' }
SoilSkipList >> findPageCandidateFor: key [
	^ (self iteratorForKey: key) page
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

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self pageRegistry initializeHeaderPage
]

{ #category : #initialization }
SoilSkipList >> initializeList [ 
	self pageRegistry 
		initializeFilesystem
]

{ #category : #'as yet unclassified' }
SoilSkipList >> iteratorForKey: key [
	| currentPage iterator right |
	currentPage := self startPage.
	iterator := SoilSkipListIterator new maxLevel: maxLevel.
	maxLevel to: 1 by: -1 do: [ :level |
		[ 
			right := currentPage rightAt: level.
			right > 0 and: [ (self pageRegistry pageAt: right) smallestKey < key ] ]
			whileTrue: [ currentPage := self pageRegistry pageAt: right  ].
			iterator at: level put: currentPage. ].
	iterator page: currentPage.
	^ iterator 
]

{ #category : #accessing }
SoilSkipList >> keySize [

	^ keySize ifNil: [ 
		keySize := self defaultKeySize ]
]

{ #category : #accessing }
SoilSkipList >> keySize: anObject [

	keySize := anObject
]

{ #category : #actions }
SoilSkipList >> load [
	maxLevel := self stream 
		position: 0;
		next.
	self readPageAt: 1
]

{ #category : #accessing }
SoilSkipList >> maxLevel [
	^ maxLevel
]

{ #category : #accessing }
SoilSkipList >> maxLevel: anInteger [ 
	maxLevel := anInteger 
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

{ #category : #'as yet unclassified' }
SoilSkipList >> startPage [
	^ self pageRegistry startPage
]

{ #category : #accessing }
SoilSkipList >> valueSize [
	^ 8
]

{ #category : #accessing }
SoilSkipList >> valueSize: anInteger [ 
	valueSize := anInteger
]

{ #category : #writing }
SoilSkipList >> writeHeaderPage [
	self pageRegistry writeHeaderPage
]

{ #category : #writing }
SoilSkipList >> writePages [
	self pageRegistry flushPages
]
