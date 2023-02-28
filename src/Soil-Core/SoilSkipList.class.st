Class {
	#name : #SoilSkipList,
	#superclass : #Object,
	#instVars : [
		'maxLevel',
		'stream',
		'path',
		'random',
		'keySize',
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
SoilSkipList >> at: aByteArray ifAbsent: aBlock [
	| key |
	key := (aByteArray class = ByteArray and: [ aByteArray size = self keySize ])
		ifTrue: [ aByteArray ]
		ifFalse: [ aByteArray asByteArray asByteArrayOfSize: self keySize ].
	^ (self findNode: key) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilSkipList >> at: aKeyObject put: anObject [
	| key iterator |
	key := "aKeyObject asSkipListKeyOfSize: self keySize."
	key := aKeyObject asByteArray asInteger.
	iterator := self iteratorForKey: key.
	iterator page hasRoom 
		ifTrue: [ iterator page addItem: (key -> anObject) ]
		ifFalse: [ 
			self pageRegistry splitPage: iterator ].
	^ anObject
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
	| page |
	page := self findPageCandidateFor: aString.
	^ (page valueAt: aString ) value
]

{ #category : #private }
SoilSkipList >> findNode: aString [ 
	| current right key |
	key := aString asSkipListKeyOfSize: self keySize.
	current := self firstPage firstItem.
	
	maxLevel to: 1 by: -1 do: [ :level |
		[ (current hasRightAt: level) and: [ (right := (current rightAt: level) realNodeIn: self) keyIsSmallerThan: key ] ]
			whileTrue: [ current := right ] .
		(current key = key) ifTrue: [ ^ current ]. 

	].
	^ nil
]

{ #category : #'as yet unclassified' }
SoilSkipList >> findPageCandidateFor: key [
	^ (self iteratorForKey: key) page
]

{ #category : #'as yet unclassified' }
SoilSkipList >> findPageForKey: aByteArray [ 
	| current |
	current := self pageRegistry pageAt: self headerPage startPageIndex.
	self halt.
]

{ #category : #accessing }
SoilSkipList >> firstPage [
	^ self pageRegistry pageAt: 1
]

{ #category : #'as yet unclassified' }
SoilSkipList >> headerPage [
	^ self pageRegistry headerPage
]

{ #category : #initialization }
SoilSkipList >> initialize [ 
	super initialize.
	random := Random seed: Time microsecondClockValue.
]

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self pageRegistry initializeHeaderPage
]

{ #category : #initialization }
SoilSkipList >> initializeList [ 
	self pageRegistry 
		initializeHeaderPage;
		initializeFirstPage
	 
]

{ #category : #'as yet unclassified' }
SoilSkipList >> insert: newNode intoLeft: leftNodes [
	| promote level |
	promote := true.
	level := 1.
	[ (level <= maxLevel) & (promote = true) ] whileTrue: [ 
		newNode rightAt: level  put: ((leftNodes at: level) rightAt: level).
		(leftNodes at: level) rightAt: level put: newNode.
		level := level + 1.
		promote := random next > 0.5 ].
]

{ #category : #'as yet unclassified' }
SoilSkipList >> iteratorForKey: key [
	| currentPage iterator right |
	currentPage := self startPage.
	iterator := SoilSkipListIterator new maxLevel: maxLevel.
	maxLevel to: 1 by: -1 do: [ :level |
		[ 
			right := currentPage rightAt: level.
			right notNil and: [ (self pageRegistry pageAt: right) smallestKey < key ] ]
			whileTrue: [ currentPage := self pageRegistry pageAt: right  ].
			iterator at: level put: currentPage. ].
	iterator page: currentPage.
	^ iterator 
]

{ #category : #'as yet unclassified' }
SoilSkipList >> iteratorForKeyY: key [
	| currentPage iterator |
	currentPage := self startPage.
	iterator := SoilSkipListIterator new maxLevel: maxLevel.
	maxLevel to: 1 by: -1 do: [ :level |
		iterator at: level put: currentPage.
		(currentPage biggestKey > key) ifTrue: [
			iterator page: currentPage.
			^ iterator ]. 
		(currentPage rightAt: level) ifNotNil: [ :right |
			currentPage := self pageRegistry pageAt: right ] ].
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

{ #category : #'as yet unclassified' }
SoilSkipList >> lowerNode [
	^ self firstPage firstItem
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
SoilSkipList >> newNode [ 
	^ SoilSkipListPage new 
		level: self maxLevel 
]

{ #category : #accessing }
SoilSkipList >> pageRegistry [
	^ pageRegistry ifNil: [ 
		pageRegistry := SoilPageRegistry new
			skipList: self ]
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

{ #category : #writing }
SoilSkipList >> writeHeaderPage [
	self pageRegistry writeHeaderPage
]

{ #category : #writing }
SoilSkipList >> writePages [
	self pageRegistry flushPages
]
