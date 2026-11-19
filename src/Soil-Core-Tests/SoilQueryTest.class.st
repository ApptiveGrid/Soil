Class {
	#name : #SoilQueryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'plain'
	],
	#category : #'Soil-Core-Tests-Query'
}

{ #category : #helpers }
SoilQueryTest >> assertBackwardIsTheReverseFor: aBlock [
	"forward and backward over the same query give the same elements in the reverse order, with an index
	and without. Answers the forward ids"
	| forward backward |
	forward := self assertSameResultFor: aBlock.
	backward := self assertSameResultFor: [ :query | aBlock value: query. query backwards ].
	self assert: backward reversed equals: forward.
	^ forward
]

{ #category : #helpers }
SoilQueryTest >> assertSameResultFor: aBlock [
	"the query runs against a collection with an index on #lastName and #compositeKey and against one with
	only the primary. The elements and their order are the same. Answers the ids"
	| withIndex withoutIndex tx tx2 |
	tx := soil newTransaction.
	tx2 := plain newTransaction.
	withIndex := self idsOf: (self queryIn: tx root using: aBlock).
	withoutIndex := self idsOf: (self queryIn: tx2 root using: aBlock).
	self assert: withoutIndex equals: withIndex.
	tx abort.
	tx2 abort.
	^ withIndex
]

{ #category : #helpers }
SoilQueryTest >> idsOf: aQuery [
	^ (aQuery iterator upToEnd collect: [ :each | each id ]) asArray
]

{ #category : #helpers }
SoilQueryTest >> newCollectionIndexed: aBoolean [
	| collection |
	collection := SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		yourself.
	aBoolean ifTrue: [
		collection
			addIndex: (SoilDerivedIndex selector: #lastName);
			addIndex: (SoilDerivedIndex selector: #compositeKey) ].
	^ collection
]

{ #category : #accessing }
SoilQueryTest >> path [
	^ 'soil-tests'
]

{ #category : #helpers }
SoilQueryTest >> person: aRow [
	^ SoilPerson new id: aRow first; lastName: aRow second; firstName: aRow third; yourself
]

{ #category : #helpers }
SoilQueryTest >> queryIn: aCollection using: aBlock [
	| query |
	query := aCollection query.
	aBlock value: query.
	^ query
]

{ #category : #helpers }
SoilQueryTest >> rows [
	^ #( #( 'p01' 'Doe' 'John' ) #( 'p02' 'Doe' 'Jane' ) #( 'p03' 'Doe' 'Jim' )
		#( 'p04' 'Roe' 'Rick' ) #( 'p05' 'Roe' 'Rose' ) #( 'p06' 'Poe' 'Pat' )
		#( 'p07' 'Moe' 'Max' ) #( 'p08' 'Zed' 'Zoe' ) #( 'p09' 'a' 'Ann' )
		#( 'p10' 'B' 'Bob' ) #( 'p11' 'Doe' 'Dan' ) )
]

{ #category : #running }
SoilQueryTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	plain := Soil path: self path , '-plain'.
	plain
		destroy;
		initializeFilesystem.
	self store: (self newCollectionIndexed: true) in: soil.
	self store: (self newCollectionIndexed: false) in: plain
]

{ #category : #helpers }
SoilQueryTest >> store: aCollection in: aSoil [
	| tx |
	tx := aSoil newTransaction.
	tx root: aCollection.
	self rows do: [ :each | tx root add: (self person: each) ].
	tx commit
]

{ #category : #running }
SoilQueryTest >> tearDown [
	soil ifNotNil: [ soil close ].
	plain ifNotNil: [ plain close ].
	super tearDown
]

{ #category : #tests }
SoilQueryTest >> testABackwardEqualQueryWithoutAnIndexStopsAtTheLimit [
	| tx calls query |
	tx := plain newTransaction.
	calls := 0.
	query := tx root query.
	query property: #lastName; equalTo: 'Doe'; backwards; limit: 2.
	query predicate: [ :each | calls := calls + 1. true ].
	self assert: (query iterator upToEnd collect: [ :each | each id ]) asArray equals: #( 'p11' 'p03' ).
	self assert: calls equals: 2.
	tx abort
]

{ #category : #tests }
SoilQueryTest >> testAComparisonNeedsAProperty [
	| tx |
	tx := soil newTransaction.
	self
		should: [ (tx root query equalTo: 'Doe'; yourself) iterator ]
		raise: SoilUnsupportedError.
	tx abort
]

{ #category : #tests }
SoilQueryTest >> testAValueTheEncodingRefusesIsAnErrorForTheScanAsForTheIndex [
	| tx |
	"an index would not have taken the person, the scan finds it when it reads"
	tx := plain newTransaction.
	tx root add: (self person: #( 'p12' nil 'Nil' )).
	self
		should: [ (tx root query property: #lastName; equalTo: 'Doe'; yourself) iterator upToEnd ]
		raise: SoilUnsupportedError.
	tx abort.
	tx := soil newTransaction.
	self
		should: [ tx root add: (self person: #( 'p12' nil 'Nil' )) ]
		raise: SoilUnsupportedError.
	tx abort
]

{ #category : #tests }
SoilQueryTest >> testAllElementsAreInPrimaryKeyOrder [
	self
		assert: (self assertSameResultFor: [ :query | ])
		equals: #( 'p01' 'p02' 'p03' 'p04' 'p05' 'p06' 'p07' 'p08' 'p09' 'p10' 'p11' )
]

{ #category : #tests }
SoilQueryTest >> testAnEqualQueryWithoutAnIndexStopsAtTheLimit [
	| tx calls query |
	tx := plain newTransaction.
	calls := 0.
	query := tx root query.
	query property: #lastName; equalTo: 'Doe'; limit: 2.
	query predicate: [ :each | calls := calls + 1. true ].
	self assert: query iterator upToEnd size equals: 2.
	self assert: calls equals: 2.
	"for a range it has to read all the hits, to sort them"
	calls := 0.
	query comparison: (SoilQueryComparison from: 'Doe' to: 'Roe').
	self assert: query iterator upToEnd size equals: 2.
	self assert: calls > 2.
	tx abort
]

{ #category : #tests }
SoilQueryTest >> testBackwardIsTheForwardOrderTurnedAroundForEveryShapeOfQuery [
	self assertBackwardIsTheReverseFor: [ :query | ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #lastName ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #lastName; equalTo: 'Doe' ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #lastName; from: 'Moe' to: 'Roe' ].
	self assertBackwardIsTheReverseFor: [ :query |
		query property: #lastName; from: 'Moe' to: 'Roe' includeFirst: false includeLast: false ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #lastName; from: 'Poe' to: nil ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #lastName; startingWith: 'Do' ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #compositeKey; startingWith: 'Roe' ].
	self assertBackwardIsTheReverseFor: [ :query | query property: #id; from: 'p03' to: 'p05' ].
	self assertBackwardIsTheReverseFor: [ :query |
		query property: #lastName; predicate: [ :each | each firstName first = $J ] ]
]

{ #category : #tests }
SoilQueryTest >> testBackwardLimitAndOffsetCountInTheDirectionOfReading [
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; equalTo: 'Doe'; backwards; offset: 1; limit: 2 ])
		equals: #( 'p03' 'p02' ).
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; backwards; offset: 2; limit: 3 ])
		equals: #( 'p05' 'p04' 'p06' ).
	self
		assert: (self assertSameResultFor: [ :query | query backwards; limit: 2 ])
		equals: #( 'p11' 'p10' )
]

{ #category : #tests }
SoilQueryTest >> testBackwardSeesTheChangesOfTheTransactionOnBothWays [
	| tx person |
	{ soil. plain } do: [ :database |
		tx := database newTransaction.
		tx root add: (self person: #( 'p12' 'Doe' 'Dave' )).
		person := tx root at: 'p01'.
		person lastName: 'Zip'.
		tx root update: person.
		tx root remove: (tx root at: 'p02').
		self
			assert: ((tx root query property: #lastName; equalTo: 'Doe'; backwards; yourself) iterator upToEnd collect: [ :each | each id ]) asArray
			equals: #( 'p12' 'p11' 'p03' ).
		tx abort ]
]

{ #category : #tests }
SoilQueryTest >> testBackwardStartsBeforeAPositionOnBothWays [
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; equalTo: 'Doe'.
			query before: (SoilQueryPosition attribute: 'Doe' primary: 'p03') ])
		equals: #( 'p02' 'p01' ).
	"the position of an element that is gone: reading backwards goes on with the one before"
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName.
			query before: (SoilQueryPosition attribute: 'Doe' primary: 'p99') ])
		equals: #( 'p11' 'p03' 'p02' 'p01' 'p10' ).
	self
		assert: (self assertSameResultFor: [ :query | query before: (SoilQueryPosition primary: 'p03') ])
		equals: #( 'p02' 'p01' )
]

{ #category : #tests }
SoilQueryTest >> testBetweenInTheOrderOfTheEncodedProperty [
	"a byte comparison: 'B' before 'a', capital letters before small ones"
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; from: 'Moe' to: 'Roe' ])
		equals: #( 'p07' 'p06' 'p04' 'p05' ).
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; from: 'Moe' to: 'Roe' includeFirst: false includeLast: false ])
		equals: #( 'p06' ).
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; from: 'Roe' to: nil ])
		equals: #( 'p04' 'p05' 'p08' 'p09' ).
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; from: nil to: 'Doe' ])
		equals: #( 'p10' 'p01' 'p02' 'p03' 'p11' )
]

{ #category : #tests }
SoilQueryTest >> testCaseOrdersTheSameOnBothWays [
	"by the encoding, not by the collation of the values"
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; limit: 2 ])
		equals: #( 'p10' 'p01' )
]

{ #category : #tests }
SoilQueryTest >> testCountIgnoresPositionOffsetAndLimit [
	| tx query |
	{ soil. plain } do: [ :database |
		tx := database newTransaction.
		query := tx root query.
		query property: #lastName; equalTo: 'Doe'; offset: 1; limit: 1.
		query after: (SoilQueryPosition attribute: 'Doe' primary: 'p02').
		self assert: query count equals: 4.
		query predicate: [ :each | each firstName size = 4 ].
		self assert: query count equals: 2.
		tx abort ]
]

{ #category : #tests }
SoilQueryTest >> testEqualToAValueIsInPrimaryKeyOrder [
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; equalTo: 'Doe' ])
		equals: #( 'p01' 'p02' 'p03' 'p11' ).
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; equalTo: 'nobody' ])
		equals: #()
]

{ #category : #tests }
SoilQueryTest >> testLimitAndOffsetCountHits [
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; equalTo: 'Doe'; offset: 1; limit: 2 ])
		equals: #( 'p02' 'p03' ).
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; offset: 3; limit: 4; predicate: [ :each | each id ~= 'p03' ] ])
		equals: #( 'p11' 'p07' 'p06' 'p04' ).
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; from: 'Moe' to: 'Roe'; offset: 10 ])
		equals: #()
]

{ #category : #tests }
SoilQueryTest >> testPagingOverThePositionOnBothWaysAndAcrossThem [
	"pages of three, each page in a transaction of its own, the position handed from one page to the
	next, also from the collection with an index to the one without and back"
	| databases |
	databases := { soil. plain }.
	#( #( 1 1 ) #( 2 2 ) #( 1 2 ) #( 2 1 ) ) do: [ :ways |
		| seen position |
		seen := OrderedCollection new.
		position := nil.
		1 to: 6 do: [ :round |
			| tx query page |
			tx := (databases at: (ways at: (round odd ifTrue: [ 1 ] ifFalse: [ 2 ]))) newTransaction.
			query := tx root query.
			query property: #lastName; limit: 3; after: position.
			page := query iterator.
			seen addAll: (page upToEnd collect: [ :each | each id ]).
			page position ifNotNil: [ :new | position := new ].
			tx abort ].
		self
			assert: seen asArray
			equals: #( 'p10' 'p01' 'p02' 'p03' 'p11' 'p07' 'p06' 'p04' 'p05' 'p08' 'p09' ) ]
]

{ #category : #tests }
SoilQueryTest >> testPositionIsBuiltFromTwoValuesAndReadsOnAtTheSamePlace [
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; equalTo: 'Doe'.
			query after: (SoilQueryPosition attribute: 'Doe' primary: 'p02') ])
		equals: #( 'p03' 'p11' ).
	"the position of an element that is gone reads on from the next one"
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName.
			query after: (SoilQueryPosition attribute: 'Doe' primary: 'p99') ])
		equals: #( 'p07' 'p06' 'p04' 'p05' 'p08' 'p09' ).
	self
		assert: (self assertSameResultFor: [ :query | query after: (SoilQueryPosition primary: 'p09') ])
		equals: #( 'p10' 'p11' ).
	self
		assert: (SoilQueryPosition attribute: 'Doe' primary: 'p02')
		equals: (SoilQueryPosition attribute: 'Doe' primary: 'p02')
]

{ #category : #tests }
SoilQueryTest >> testPositionOfTheIteratorIsMadeOfTheValuesOfTheLastHit [
	| tx iterator |
	tx := soil newTransaction.
	iterator := (tx root query property: #lastName; equalTo: 'Roe'; yourself) iterator.
	self assert: iterator position isNil.
	iterator next.
	self assert: iterator position equals: (SoilQueryPosition attribute: 'Roe' primary: 'p04').
	iterator := tx root query iterator.
	iterator next; next.
	self assert: iterator position equals: (SoilQueryPosition primary: 'p02').
	tx abort
]

{ #category : #tests }
SoilQueryTest >> testPredicateChecksTheRest [
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; equalTo: 'Doe'; predicate: [ :each | each firstName size = 4 ] ])
		equals: #( 'p01' 'p02' ).
	self
		assert: (self assertSameResultFor: [ :query |
			query property: #lastName; predicate: [ :each | each firstName first = $J ] ])
		equals: #( 'p01' 'p02' 'p03' ).
	self
		assert: (self assertSameResultFor: [ :query | query predicate: [ :each | each lastName = 'Roe' ] ])
		equals: #( 'p04' 'p05' )
]

{ #category : #tests }
SoilQueryTest >> testProtocolIsTheSameForIndexAndScan [
	| tx tx2 index scan |
	tx := soil newTransaction.
	tx2 := plain newTransaction.
	index := (tx root query property: #lastName; yourself) iterator.
	scan := (tx2 root query property: #lastName; yourself) iterator.
	self assert: index atEnd equals: scan atEnd.
	self assert: index first id equals: scan first id.
	self assert: (index next: 2) size equals: (scan next: 2) size.
	self assert: index next id equals: scan next id.
	self assert: index upToEnd size equals: scan upToEnd size.
	self assert: index atEnd.
	self assert: scan atEnd.
	self assert: scan next isNil.
	tx abort.
	tx2 abort
]

{ #category : #tests }
SoilQueryTest >> testSeenAreTheChangesOfTheTransactionOnBothWays [
	| tx person |
	{ soil. plain } do: [ :database |
		tx := database newTransaction.
		tx root add: (self person: #( 'p12' 'Doe' 'Dave' )).
		person := tx root at: 'p01'.
		person lastName: 'Zip'.
		tx root update: person.
		tx root remove: (tx root at: 'p02').
		self
			assert: ((tx root query property: #lastName; equalTo: 'Doe'; yourself) iterator upToEnd collect: [ :each | each id ]) asArray
			equals: #( 'p03' 'p11' 'p12' ).
		self
			assert: ((tx root query property: #lastName; equalTo: 'Zip'; yourself) iterator upToEnd collect: [ :each | each id ]) asArray
			equals: #( 'p01' ).
		tx abort ]
]

{ #category : #tests }
SoilQueryTest >> testStartingWithAStringAndAComposedAttribute [
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName; startingWith: 'Do' ])
		equals: #( 'p01' 'p02' 'p03' 'p11' ).
	self
		assert: (self assertSameResultFor: [ :query | query property: #compositeKey; startingWith: 'Roe' ])
		equals: #( 'p04' 'p05' ).
	self
		assert: (self assertSameResultFor: [ :query | query property: #compositeKey; startingWith: 'RoeRo' ])
		equals: #( 'p05' )
]

{ #category : #tests }
SoilQueryTest >> testThePageBeforeAcrossIndexAndScan [
	"forward pages of three over #lastName in one collection, then the page before the third page read
	backwards from the place of its first hit in the other collection, and turned around: it is the
	second page. The third page starts inside the run of equal values of 'Roe'"
	| databases |
	databases := { soil. plain }.
	#( #( 1 2 ) #( 2 1 ) ) do: [ :ways |
		| position second thirdFirst tx query iterator |
		position := nil.
		1 to: 3 do: [ :round |
			tx := (databases at: ways first) newTransaction.
			query := tx root query.
			query property: #lastName; limit: 3; after: position.
			iterator := query iterator.
			round = 3
				ifTrue: [ iterator next. thirdFirst := iterator position ]
				ifFalse: [
					round = 2 ifTrue: [ second := iterator upToEnd collect: [ :each | each id ] ].
					round = 1 ifTrue: [ iterator upToEnd ].
					position := iterator position ].
			tx abort ].
		tx := (databases at: ways second) newTransaction.
		query := tx root query.
		query property: #lastName; before: thirdFirst; limit: 3.
		self
			assert: (query iterator upToEnd collect: [ :each | each id ]) asArray reversed
			equals: second asArray.
		tx abort ]
]

{ #category : #tests }
SoilQueryTest >> testThePropertyCanBeThePrimary [
	self
		assert: (self assertSameResultFor: [ :query | query property: #id; from: 'p03' to: 'p05' ])
		equals: #( 'p03' 'p04' 'p05' )
]

{ #category : #tests }
SoilQueryTest >> testTheQueryCanBeUsedAgain [
	| tx query one two |
	tx := plain newTransaction.
	query := tx root query.
	query property: #lastName; equalTo: 'Doe'.
	one := query iterator.
	two := query iterator.
	one next.
	self assert: two next id equals: 'p01'.
	self assert: one next id equals: 'p02'.
	tx abort
]

{ #category : #tests }
SoilQueryTest >> testTheWholePropertyIsInTheOrderOfTheProperty [
	self
		assert: (self assertSameResultFor: [ :query | query property: #lastName ])
		equals: #( 'p10' 'p01' 'p02' 'p03' 'p11' 'p07' 'p06' 'p04' 'p05' 'p08' 'p09' )
]
