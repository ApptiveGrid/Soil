Class {
	#name : #SoilIndexIteratorPreviousTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilIndexIteratorPreviousTest >> keyOf: anId in: aCollection [
	"the index key of an id of the primary"
	^ aCollection primaryIndex indexKey: (aCollection primaryIndex layout keyFor: anId primaryKey: nil)
]

{ #category : #accessing }
SoilIndexIteratorPreviousTest >> path [
	^ 'soil-tests'
]

{ #category : #helpers }
SoilIndexIteratorPreviousTest >> person: anId [
	^ SoilPerson new id: anId; lastName: 'Doe'; firstName: 'F' , anId; yourself
]

{ #category : #helpers }
SoilIndexIteratorPreviousTest >> previousKeyTo: anId in: aTransaction [
	"the id of the entry at or before anId, nil if none"
	| iterator found |
	iterator := aTransaction root primaryIndex newIterator.
	found := iterator previousKeyCloseTo: (self keyOf: anId in: aTransaction root).
	^ found ifNotNil: [ (iterator at: found) id ]
]

{ #category : #running }
SoilIndexIteratorPreviousTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	self storeIds: #( 'p01' 'p03' 'p05' 'p07' )
]

{ #category : #helpers }
SoilIndexIteratorPreviousTest >> storeIds: someIds [
	| tx |
	tx := soil newTransaction.
	tx root: (SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		yourself).
	someIds do: [ :each | tx root add: (self person: each) ].
	tx commit
]

{ #category : #running }
SoilIndexIteratorPreviousTest >> tearDown [
	soil ifNotNil: [ soil close ].
	super tearDown
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testAKeyThatIsNotThereAnswersTheNextSmallerOne [
	| tx |
	tx := soil newTransaction.
	self assert: (self previousKeyTo: 'p04' in: tx) equals: 'p03'.
	self assert: (self previousKeyTo: 'p06' in: tx) equals: 'p05'.
	tx abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testAKeyThatIsThereAnswersItself [
	| tx |
	tx := soil newTransaction.
	self assert: (self previousKeyTo: 'p03' in: tx) equals: 'p03'.
	self assert: (self previousKeyTo: 'p01' in: tx) equals: 'p01'.
	self assert: (self previousKeyTo: 'p07' in: tx) equals: 'p07'.
	tx abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testALargerKeyThanAllAnswersTheLast [
	| tx |
	tx := soil newTransaction.
	self assert: (self previousKeyTo: 'p99' in: tx) equals: 'p07'.
	tx abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testASmallerKeyThanAllAnswersNil [
	| tx |
	tx := soil newTransaction.
	self assert: (self previousKeyTo: 'p00' in: tx) isNil.
	tx abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testAnEmptyIndexAnswersNil [
	| tx |
	tx := soil newTransaction.
	tx root remove: (tx root at: 'p01').
	tx root remove: (tx root at: 'p03').
	tx root remove: (tx root at: 'p05').
	tx root remove: (tx root at: 'p07').
	self assert: (self previousKeyTo: 'p04' in: tx) isNil.
	tx abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testAnEntryRemovedInTheTransactionIsStepped [
	| tx |
	tx := soil newTransaction.
	tx root remove: (tx root at: 'p03').
	self assert: (self previousKeyTo: 'p03' in: tx) equals: 'p01'.
	self assert: (self previousKeyTo: 'p04' in: tx) equals: 'p01'.
	tx root remove: (tx root at: 'p01').
	self assert: (self previousKeyTo: 'p04' in: tx) isNil.
	tx abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testAnOlderReaderStillSeesAnEntryRemovedSinceThen [
	| reader tx |
	reader := soil newTransaction.
	reader root values.
	tx := soil newTransaction.
	tx root remove: (tx root at: 'p03').
	tx commit.
	self assert: (self previousKeyTo: 'p03' in: reader) equals: 'p03'.
	self assert: (self previousKeyTo: 'p04' in: reader) equals: 'p03'.
	reader abort
]

{ #category : #tests }
SoilIndexIteratorPreviousTest >> testReadingBackwardsGoesOnBeforeTheAnsweredEntry [
	| tx iterator |
	tx := soil newTransaction.
	iterator := tx root primaryIndex newIterator.
	iterator previousKeyCloseTo: (self keyOf: 'p04' in: tx root).
	self assert: iterator previous id equals: 'p01'.
	tx abort
]
