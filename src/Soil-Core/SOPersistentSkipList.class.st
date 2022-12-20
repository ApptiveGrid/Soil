Class {
	#name : #SOPersistentSkipList,
	#superclass : #SOSkipList,
	#instVars : [
		'path',
		'stream',
		'pages',
		'random',
		'keySize'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #adding }
SOPersistentSkipList >> addNode: aNode [
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
SOPersistentSkipList >> at: aByteArray [ 
	^ self 
		at: aByteArray 
		ifAbsent: [ Error signal: 'no found' ]
]

{ #category : #private }
SOPersistentSkipList >> at: aByteArray ifAbsent: aBlock [
	| key |
	key := (aByteArray class = ByteArray and: [ aByteArray size = self keySize ])
		ifTrue: [ aByteArray ]
		ifFalse: [ aByteArray asByteArray asByteArrayOfSize: self keySize ].
	^ (self findNode: key) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SOPersistentSkipList >> at: aString ifPresent: aBlock [
	| value |
	value := self at: aString ifAbsent: [ nil ].
	^ value 
		ifNotNil: [ aBlock value: value ]
		ifNil: [ nil ]
]

{ #category : #accessing }
SOPersistentSkipList >> at: aKeyObject put: anObject [
	| levelNodes newNode key |
	key := aKeyObject asSkipListKeyOfSize: self keySize.
	levelNodes := self 
		findLeftNodesOf: key
		ifKeyPresent: [ :node | 
			"if the key is present we just need to overwrite its value 
			as all other references are key dependent and stay untouched"
			node value: anObject. 
			^ anObject ]. 
	newNode := self newNode.
	newNode 
		key: key;
		value: anObject.
	self insert: newNode intoLeft: levelNodes.
	self addNode: newNode.
	 ^ nil
]

{ #category : #'initialize-release' }
SOPersistentSkipList >> close [ 
	stream ifNotNil: [  
		stream close.
		stream := nil ]
]

{ #category : #accessing }
SOPersistentSkipList >> defaultKeySize [
	^ 16
]

{ #category : #deleting }
SOPersistentSkipList >> destroy [
	path ensureDelete 
]

{ #category : #'instance creation' }
SOPersistentSkipList >> filePageSize [
	"most OSses use a file page size of 4k today"
	^ 4096
]

{ #category : #accessing }
SOPersistentSkipList >> findLeftNodesOf: key ifKeyPresent: aBlock [
	| leftNodes current |
	leftNodes := Array new: maxLevel.
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
SOPersistentSkipList >> findNode: aString [ 
	| current right |
	current := self firstPage firstItem.
	
	maxLevel to: 1 by: -1 do: [ :level |
		[ (current hasRightAt: level) and: [ (right := (current rightAt: level) realNodeIn: self) keyIsSmallerThan: aString ] ]
			whileTrue: [ current := right ] .
		(current key = aString) ifTrue: [ ^ current ]. 

	].
	^ nil
]

{ #category : #'as yet unclassified' }
SOPersistentSkipList >> findPageForKey: aByteArray [ 
	| index |
	index := 1.
	[ index <= pages size and: [ (self pageAt: index) fitsKey: aByteArray ] ]
		whileFalse: [ index := index + 1 ].
	^ self pageAt: index
]

{ #category : #accessing }
SOPersistentSkipList >> firstPage [
	^ self pageAt: 1
]

{ #category : #private }
SOPersistentSkipList >> headerLength [
	^ 1
]

{ #category : #initialization }
SOPersistentSkipList >> initialize [ 
	super initialize.
	pages := OrderedCollection new.
	random := Random seed: Time microsecondClockValue.
]

{ #category : #initialization }
SOPersistentSkipList >> initializeList [ 
	self writeHeader.
	self writeFirstPage
	 
]

{ #category : #'as yet unclassified' }
SOPersistentSkipList >> insert: newNode intoLeft: leftNodes [
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
SOPersistentSkipList >> keySize [

	^ keySize ifNil: [ 
		keySize := self defaultKeySize ]
]

{ #category : #accessing }
SOPersistentSkipList >> keySize: anObject [

	keySize := anObject
]

{ #category : #actions }
SOPersistentSkipList >> load [
	maxLevel := self stream 
		position: 0;
		next.
	self readPageAt: 1
]

{ #category : #'as yet unclassified' }
SOPersistentSkipList >> lowerNode [
	^ self firstPage firstItem
]

{ #category : #'instance creation' }
SOPersistentSkipList >> newFilePage [ 	
	^ SOSkipListPage new 
		list: self;
		keySize: self keySize
]

{ #category : #'instance creation' }
SOPersistentSkipList >> newPage [
	| page |
	page := self newFilePage.
	pages add: page.
	page 
		pageNumber: pages size.
	^ page
]

{ #category : #accessing }
SOPersistentSkipList >> pageAt: anInteger [
	(anInteger > pages size) ifTrue: [ 
		self readPageAt: anInteger ].  
	^ (pages at: anInteger) ifNil: [ 
		self readPageAt: anInteger ]
]

{ #category : #accessing }
SOPersistentSkipList >> pages [
	^ pages
]

{ #category : #accessing }
SOPersistentSkipList >> path [

	^ path
]

{ #category : #accessing }
SOPersistentSkipList >> path: aStringOrFileReference [

	path := aStringOrFileReference asFileReference 
]

{ #category : #'instance creation' }
SOPersistentSkipList >> positionOfPage: aPage [ 
	^ self headerLength + ((aPage pageNumber - 1) * self filePageSize)
]

{ #category : #accessing }
SOPersistentSkipList >> readPageAt: anInteger [
	| page |
	stream position: (self headerLength + ((anInteger - 1) * self pageSize)).
	page := SOSkipListPage new 
		list: self;
		pageNumber: anInteger;
		keySize: self keySize;
		readFrom: stream.
	(pages size > anInteger) ifFalse: [ 
		 pages := pages grownBy: (anInteger - pages size)].
	pages at: anInteger put: page.
	^ page
]

{ #category : #'as yet unclassified' }
SOPersistentSkipList >> rightOf: aNode atLevel: anInteger [ 
	^ (aNode rightAt: anInteger)
		ifNotNil: [ :proxy | (self pageAt: proxy pageNumber) itemAt: proxy pageIndex ]
	
]

{ #category : #initialization }
SOPersistentSkipList >> stream [ 
	^ stream ifNil: [
		stream := path binaryReadWriteStream ]
]

{ #category : #writing }
SOPersistentSkipList >> writeFirstPage [
	| page |
	stream position: self headerLength.
	page := self newFilePage  
		pageNumber: 1.
	pages add: page.
	page addNode: (self newSentinelNode
		beLower;
		initializeKeyOfSize: self keySize).
	page addNode: (self newSentinelNode 
		beUpper;
		initializeKeyOfSize: self keySize).
	page writeOn: stream.
	stream flush.
	^ page 
]

{ #category : #initialization }
SOPersistentSkipList >> writeHeader [ 
	self stream 
		position: 0;
		nextPut: maxLevel;
		flush
]

{ #category : #writing }
SOPersistentSkipList >> writePages [

	pages
		reject: [ :page | page isNil ]
		thenDo: [ :page | page writeOn: stream ]
]
