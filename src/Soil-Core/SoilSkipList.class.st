Class {
	#name : #SoilSkipList,
	#superclass : #Object,
	#instVars : [
		'maxLevel',
		'stream',
		'pages',
		'path',
		'random',
		'keySize',
		'pageRegistry'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #adding }
SoilSkipList >> addNode: aNode [
	| page newPage pageNumber lookingForPage nextPage |
	page := self findPageForKey: aNode key.
	pageNumber := page pageNumber.
	lookingForPage := aNode.
	[ pageNumber <= pages size ] whileTrue: [
		nextPage := pages at: pageNumber.
		nextPage hasRoom 
			ifTrue: [ 
				nextPage addNode: lookingForPage.
				^ aNode ]
			ifFalse: [ | node |
				node := nextPage removeLastNode.
				nextPage addNode: lookingForPage.
				lookingForPage := node ].
			pageNumber := pageNumber + 1 ].
			  
		newPage := self newPage.
		newPage addNode: lookingForPage.
]

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
SoilSkipList >> at: aString ifPresent: aBlock [
	| value |
	value := self at: aString ifAbsent: [ nil ].
	^ value 
		ifNotNil: [ aBlock value: value ]
		ifNil: [ nil ]
]

{ #category : #accessing }
SoilSkipList >> at: aKeyObject put: anObject [
	| key iterator |
	key := "aKeyObject asSkipListKeyOfSize: self keySize."
	key := aKeyObject asByteArray asInteger.
	iterator := self findPageCandidateFor: key.
	iterator page hasRoom 
		ifTrue: [ iterator page addItem: (key -> anObject) ]
		ifFalse: [ 
			self pageRegistry splitPage: iterator ].
	^ anObject
]

{ #category : #'initialize-release' }
SoilSkipList >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
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
	^ (self findNode: aString)
		ifNotNil: [ :node | node value ]
]

{ #category : #accessing }
SoilSkipList >> findLeftNodesOf: key ifKeyPresent: aBlock [
	| leftNodes current page |
	leftNodes := Array new: maxLevel.
	
	page := self findPageCandidateFor: key.
	self halt.
	
	current := self lowerNode.
	
	maxLevel to: 1 by: -1 do: [ :lvl | | right |
		[ (current key = key) ifTrue: [ 
			aBlock value: current ]. 
		right := self rightOf: current atLevel: lvl.
		 	right notNil and: [ right keyIsSmallerThan: key ] ]
				whileTrue: [ current := right ] .
		leftNodes at: lvl put: current
	].
	^ leftNodes 
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
	pages := OrderedCollection new.
	random := Random seed: Time microsecondClockValue.
]

{ #category : #writing }
SoilSkipList >> initializeHeaderPage [
	self pageRegistry initializeHeaderPage
]

{ #category : #initialization }
SoilSkipList >> initializeList [ 
	self open.
	"self writeHeader.
	self writeFirstPage"
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
SoilSkipList >> newFilePage [ 	
	^ SOSkipListPage new 
		list: self;
		keySize: self keySize
]

{ #category : #'instance creation' }
SoilSkipList >> newNode [ 
	^ SoilSkipListPage new 
		level: self maxLevel 
]

{ #category : #'instance creation' }
SoilSkipList >> newSentinelNode [ 
	^ SOSkipListSentinelNode new 
		level: self maxLevel 
]

{ #category : #'instance creation' }
SoilSkipList >> open [ 
	"stream := SOLockableStream path: path"
]

{ #category : #accessing }
SoilSkipList >> pageRegistry [
	^ pageRegistry ifNil: [ 
		pageRegistry := SoilPageRegistry new
			skipList: self ]
]

{ #category : #accessing }
SoilSkipList >> path [

	^ path
]

{ #category : #accessing }
SoilSkipList >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #'instance creation' }
SoilSkipList >> positionOfPage: aPage [ 
	^ self headerLength + ((aPage pageNumber - 1) * self filePageSize)
]

{ #category : #'as yet unclassified' }
SoilSkipList >> rightOf: aNode atLevel: anInteger [ 
	^ (aNode rightAt: anInteger)
		ifNotNil: [ :proxy | (self pageAt: proxy pageNumber) itemAt: proxy pageIndex ]
	
]

{ #category : #'as yet unclassified' }
SoilSkipList >> startPage [
	^ self pageRegistry startPage
]

{ #category : #initialization }
SoilSkipList >> stream [ 
	^ stream
]

{ #category : #initialization }
SoilSkipList >> writeHeader [ 
	self stream 
		position: 0;
		nextPut: maxLevel;
		flush
]

{ #category : #writing }
SoilSkipList >> writeHeaderPage [
	self pageRegistry writeHeaderPage
]

{ #category : #writing }
SoilSkipList >> writePages [
	self pageRegistry flushPages
]
