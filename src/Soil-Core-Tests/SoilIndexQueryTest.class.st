Class {
	#name : #SoilIndexQueryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilIndexQueryTest >> commitPersons: someRows [
	"someRows are { id. last name. first name }"
	| tx |
	tx := soil newTransaction.
	tx root: self newCollection.
	someRows do: [ :each |
		tx root add: (SoilPerson new id: each first; lastName: each second; firstName: each third; yourself) ].
	tx commit
]

{ #category : #helpers }
SoilIndexQueryTest >> ids: aCollection [
	^ (aCollection collect: [ :each | each id ]) asArray
]

{ #category : #helpers }
SoilIndexQueryTest >> newCollection [
	^ SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		addIndex: (SoilDerivedIndex selector: #lastName);
		addIndex: (SoilDerivedIndex selector: #compositeKey);
		addIndex: (SoilDerivedIndex uniqueSelector: #firstName keySize: 16);
		yourself
]

{ #category : #helpers }
SoilIndexQueryTest >> rows [
	^ #( #( 'p01' 'Doe' 'John' ) #( 'p02' 'Doe' 'Jane' ) #( 'p03' 'Doe' 'Jim' )
		#( 'p04' 'Roe' 'Rick' ) #( 'p05' 'Roe' 'Rose' ) #( 'p06' 'Poe' 'Pat' )
		#( 'p07' 'Moe' 'Max' ) #( 'p08' 'Zed' 'Zoe' ) )
]

{ #category : #accessing }
SoilIndexQueryTest >> path [
	^ 'soil-tests'
]

{ #category : #running }
SoilIndexQueryTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilIndexQueryTest >> tearDown [
	soil ifNotNil: [ soil close ].
	super tearDown
]

{ #category : #tests }
SoilIndexQueryTest >> testAfterIsExclusive [
	| tx query position |
	self commitPersons: self rows.
	tx := soil newTransaction.
	query := (tx root indexFor: #lastName) queryFor: 'Doe'.
	position := query iterator next; next; position.
	self
		assert: (self ids: (query copy after: position; yourself) iterator upToEnd)
		equals: #( 'p03' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testAfterAKeyThatIsGoneReadsOnFromTheNextOne [
	| tx tx2 position |
	self commitPersons: self rows.
	tx := soil newTransaction.
	position := ((tx root indexFor: #lastName) query iterator next: 2; yourself) position.
	tx abort.
	"p02 is removed, the entry the position names is gone"
	tx := soil newTransaction.
	tx root remove: (tx root at: 'p02').
	tx commit.

	tx2 := soil newTransaction.
	self
		assert: (self ids: (((tx2 root indexFor: #lastName) query after: position; yourself) iterator next: 2))
		equals: #( 'p03' 'p07' ).
	tx2 abort
]

{ #category : #tests }
SoilIndexQueryTest >> testAtAnsAtIfAbsentFindByPrimaryValue [
	| tx |
	self commitPersons: self rows.
	tx := soil newTransaction.
	self assert: (tx root at: 'p04') lastName equals: 'Roe'.
	self assert: (tx root at: 'p99' ifAbsent: [ #none ]) equals: #none.
	self should: [ tx root at: 'p99' ] raise: KeyNotFound.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testCountIgnoresStartOffsetAndLimit [
	| tx query |
	self commitPersons: self rows.
	tx := soil newTransaction.
	query := (tx root indexFor: #lastName) queryFor: 'Doe'.
	query limit: 1; offset: 1; after: (query iterator next; position).
	self assert: query count equals: 3.
	query predicate: [ :each | each firstName first = $J and: [ each firstName size = 4 ] ].
	self assert: query count equals: 2.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testEmptyRangeDeliversNothing [
	| tx iterator |
	self commitPersons: self rows.
	tx := soil newTransaction.
	iterator := ((tx root indexFor: #lastName) queryFor: 'Nobody') iterator.
	self assert: iterator atEnd.
	self assert: iterator next isNil.
	self assert: iterator upToEnd isEmpty.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testEntriesAreSeenThatTheTransactionChanged [
	| tx person |
	self commitPersons: self rows.
	tx := soil newTransaction.
	tx root add: (SoilPerson new id: 'p09'; lastName: 'Doe'; firstName: 'Dan'; yourself).
	self assert: (self ids: ((tx root indexFor: #lastName) find: 'Doe')) equals: #( 'p01' 'p02' 'p03' 'p09' ).
	person := tx root at: 'p01'.
	person lastName: 'Zip'.
	tx root update: person.
	self assert: (self ids: ((tx root indexFor: #lastName) find: 'Doe')) equals: #( 'p02' 'p03' 'p09' ).
	tx root remove: (tx root at: 'p02').
	self assert: (self ids: ((tx root indexFor: #lastName) find: 'Doe')) equals: #( 'p03' 'p09' ).
	self assert: (self ids: ((tx root indexFor: #lastName) queryFor: 'Zip') iterator upToEnd) equals: #( 'p01' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testFindStaysAThinWrapAroundTheQuery [
	| tx |
	self commitPersons: self rows.
	tx := soil newTransaction.
	self assert: (self ids: ((tx root indexFor: #lastName) find: 'Roe')) equals: #( 'p04' 'p05' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testFirstStartsTheQueryOver [
	| tx iterator |
	self commitPersons: self rows.
	tx := soil newTransaction.
	iterator := ((tx root indexFor: #lastName) queryFor: 'Doe') iterator.
	iterator next; next.
	self assert: iterator first id equals: 'p01'.
	self assert: iterator next id equals: 'p02'.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testLimitCountsHitsNotEntries [
	| tx query |
	self commitPersons: self rows.
	tx := soil newTransaction.
	query := (tx root indexFor: #lastName) query.
	query limit: 2.
	self assert: (self ids: query iterator upToEnd) size equals: 2.
	"with a predicate it reads on until there are enough hits"
	query predicate: [ :each | each lastName = 'Roe' or: [ each lastName = 'Zed' ] ].
	self assert: (self ids: query iterator upToEnd) equals: #( 'p04' 'p05' ).
	query limit: 3.
	self assert: (self ids: query iterator upToEnd) equals: #( 'p04' 'p05' 'p08' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testOffsetSkipsHitsAfterTheStart [
	| tx query |
	self commitPersons: self rows.
	tx := soil newTransaction.
	query := (tx root indexFor: #lastName) queryFor: 'Doe'.
	query offset: 1.
	self assert: (self ids: query iterator upToEnd) equals: #( 'p02' 'p03' ).
	query predicate: [ :each | each firstName ~= 'Jane' ].
	self assert: (self ids: query iterator upToEnd) equals: #( 'p03' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testOlderReaderStillSeesTheOldState [
	| reader tx |
	self commitPersons: self rows.
	reader := soil newTransaction.
	(reader root indexFor: #lastName) find: 'Doe'.
	tx := soil newTransaction.
	tx root remove: (tx root at: 'p01').
	tx commit.
	self assert: (self ids: ((reader root indexFor: #lastName) find: 'Doe')) equals: #( 'p01' 'p02' 'p03' ).
	self assert: (reader root at: 'p01' ifAbsent: [ nil ]) notNil.
	reader abort
]

{ #category : #tests }
SoilIndexQueryTest >> testPagingOverPositionAcrossTransactionsHasNoGapAndNoDouble [
	"400 entries of one attribute value, more than a page of the index holds, read in pages of 37
	each in a transaction of its own"
	| tx position all page ids |
	self commitPersons: ((1 to: 400) collect: [ :n |
		| id |
		id := 'p' , (n printPaddedWith: $0 to: 3).
		{ id. 'Doe'. 'x' , id } ]).
	all := OrderedCollection new.
	position := nil.
	[ tx := soil newTransaction.
	  page := ((tx root indexFor: #lastName) queryFor: 'Doe')
		after: position;
		limit: 37;
		iterator.
	  ids := self ids: page upToEnd.
	  all addAll: ids.
	  position := page position.
	  tx abort.
	  ids isEmpty ] whileFalse.
	self assert: all size equals: 400.
	self assert: all asSet size equals: 400.
	self assert: all asArray equals: all asSortedCollection asArray
]

{ #category : #tests }
SoilIndexQueryTest >> testPositionInTheMiddleOfEqualAttributes [
	| tx first more |
	self commitPersons: self rows.
	tx := soil newTransaction.
	first := ((tx root indexFor: #lastName) queryFor: 'Roe') iterator.
	first next.
	more := (((tx root indexFor: #lastName) queryFor: 'Roe') after: first position; yourself) iterator.
	self assert: (self ids: more upToEnd) equals: #( 'p05' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testPrimaryAndUniqueDerivedIndexCanBeQueried [
	| tx |
	self commitPersons: self rows.
	tx := soil newTransaction.
	self
		assert: (self ids: (tx root primaryIndex queryFrom: 'p02' to: 'p04') iterator upToEnd)
		equals: #( 'p02' 'p03' 'p04' ).
	self
		assert: (self ids: ((tx root indexFor: #firstName) queryFor: 'Pat') iterator upToEnd)
		equals: #( 'p06' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testProtocolIsTheSameAsTheIndexIteratorsForTheWholeIndex [
	| tx plain query |
	self commitPersons: self rows.
	tx := soil newTransaction.
	plain := (tx root indexFor: #lastName) newIterator.
	query := (tx root indexFor: #lastName) query iterator.
	self assert: plain atEnd equals: query atEnd.
	self assert: plain first id equals: query first id.
	self assert: (self ids: (plain next: 2)) equals: (self ids: (query next: 2)).
	self assert: plain next id equals: query next id.
	self assert: plain atEnd equals: query atEnd.
	self assert: (self ids: plain upToEnd) equals: (self ids: query upToEnd).
	self assert: plain atEnd equals: query atEnd.
	self assert: plain atEnd.
	self assert: plain next isNil.
	self assert: query next isNil.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testProtocolDoRestartsForBothIterators [
	| tx plain query fromPlain fromQuery |
	self commitPersons: self rows.
	tx := soil newTransaction.
	plain := (tx root indexFor: #lastName) newIterator.
	query := (tx root indexFor: #lastName) query iterator.
	plain next; next.
	query next; next.
	fromPlain := OrderedCollection new.
	fromQuery := OrderedCollection new.
	plain do: [ :each | fromPlain add: each id ].
	query do: [ :each | fromQuery add: each id ].
	self assert: fromPlain asArray equals: fromQuery asArray.
	self assert: fromQuery size equals: 8.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testAtEndLooksAheadWithAPredicateAndKeepsTheHit [
	| tx iterator |
	self commitPersons: self rows.
	tx := soil newTransaction.
	iterator := ((tx root indexFor: #lastName) query predicate: [ :each | each lastName = 'Zed' ]; yourself) iterator.
	self deny: iterator atEnd.
	self assert: iterator position isNil.
	self assert: iterator next id equals: 'p08'.
	self assert: iterator atEnd.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testQueryDescribesAndIteratorsAreIndependent [
	| tx query one two |
	self commitPersons: self rows.
	tx := soil newTransaction.
	query := (tx root indexFor: #lastName) queryFor: 'Doe'.
	one := query iterator.
	two := query iterator.
	one next.
	self assert: two next id equals: 'p01'.
	self assert: one next id equals: 'p02'.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testRangeEqualStartingWithAndFromTo [
	| tx index |
	self commitPersons: self rows.
	tx := soil newTransaction.
	index := tx root indexFor: #lastName.
	self assert: (self ids: (index queryFor: 'Roe') iterator upToEnd) equals: #( 'p04' 'p05' ).
	self assert: (self ids: (index queryStartingWith: 'Do') iterator upToEnd) equals: #( 'p01' 'p02' 'p03' ).
	self assert: (self ids: (index queryStartingWith: '') iterator upToEnd) size equals: 8.
	"from Moe to Roe, both included, in the order of the attribute"
	self
		assert: (self ids: (index queryFrom: 'Moe' to: 'Roe') iterator upToEnd)
		equals: #( 'p07' 'p06' 'p04' 'p05' ).
	self assert: (self ids: index query iterator upToEnd) size equals: 8.
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testStartingWithReadsTheFrontOfACompositeAttribute [
	| tx |
	self commitPersons: self rows.
	tx := soil newTransaction.
	self
		assert: (self ids: ((tx root indexFor: #compositeKey) queryStartingWith: 'Roe') iterator upToEnd)
		equals: #( 'p04' 'p05' ).
	self
		assert: (self ids: ((tx root indexFor: #compositeKey) queryStartingWith: 'RoeRo') iterator upToEnd)
		equals: #( 'p05' ).
	tx abort
]

{ #category : #tests }
SoilIndexQueryTest >> testStartingWithIsRefusedForANumberAndForTooMuch [
	| layout |
	layout := SoilDerivedKeyLayout keySize: 16 unique: false primaryKeySize: 8.
	self should: [ layout rangeStartingWith: 5 ] raise: SoilUnsupportedError.
	self should: [ layout rangeStartingWith: '123456789' ] raise: SoilUnsupportedError
]

{ #category : #tests }
SoilIndexQueryTest >> testWholeIndexIsInKeyOrder [
	| tx |
	self commitPersons: self rows.
	tx := soil newTransaction.
	self
		assert: (self ids: ((tx root indexFor: #lastName) query iterator upToEnd))
		equals: #( 'p01' 'p02' 'p03' 'p07' 'p06' 'p04' 'p05' 'p08' ).
	tx abort
]
