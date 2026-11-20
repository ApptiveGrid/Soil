Class {
	#name : #SoilIndexRebuildTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilIndexRebuildTest >> commitCollectionWith: someRows [
	"a collection with the primary id and an index on the last name, someRows are { id. last name. first name }"
	| tx |
	tx := soil newTransaction.
	tx root: (SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		addIndex: (SoilDerivedIndex selector: #lastName);
		yourself).
	someRows do: [ :each | tx root add: (self person: each) ].
	tx commit
]

{ #category : #helpers }
SoilIndexRebuildTest >> idsOf: aCollection [
	^ (aCollection collect: [ :each | each id ]) asArray
]

{ #category : #accessing }
SoilIndexRebuildTest >> path [
	^ 'soil-tests'
]

{ #category : #helpers }
SoilIndexRebuildTest >> person: aRow [
	^ SoilPerson new id: aRow first; lastName: aRow second; firstName: aRow third; yourself
]

{ #category : #helpers }
SoilIndexRebuildTest >> rows [
	^ #( #( 'p01' 'Doe' 'John' ) #( 'p02' 'Doe' 'Jane' ) #( 'p03' 'Roe' 'Rick' ) #( 'p04' 'Poe' 'Pat' ) )
]

{ #category : #running }
SoilIndexRebuildTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	self commitCollectionWith: self rows
]

{ #category : #running }
SoilIndexRebuildTest >> tearDown [
	soil ifNotNil: [ soil close ].
	super tearDown
]

{ #category : #tests }
SoilIndexRebuildTest >> testAQueryAnswersTheSameBeforeAndAfterAddIndexAndAfterRemoveIndex [
	| tx before during after index |
	tx := soil newTransaction.
	before := self idsOf: (tx root query property: #firstName; yourself) iterator upToEnd.
	index := tx root addIndex: (SoilDerivedIndex selector: #firstName).
	during := self idsOf: (tx root query property: #firstName; yourself) iterator upToEnd.
	tx root removeIndex: index.
	after := self idsOf: (tx root query property: #firstName; yourself) iterator upToEnd.
	self assert: during equals: before.
	self assert: after equals: before.
	tx abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testASecondIndexOnTheSamePropertyIsRefused [
	| tx |
	tx := soil newTransaction.
	self should: [ tx root addIndex: (SoilDerivedIndex selector: #lastName) ] raise: SoilUnsupportedError.
	self should: [ tx root addIndex: (SoilDerivedIndex selector: #id) ] raise: SoilUnsupportedError.
	tx abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testATransactionThatOnlyReadsDoesNotFail [
	| reader builder |
	reader := soil newTransaction.
	reader root values.
	builder := soil newTransaction.
	builder root addIndex: (SoilDerivedIndex selector: #firstName).
	builder commit.
	self shouldnt: [ reader commit ] raise: Error
]

{ #category : #tests }
SoilIndexRebuildTest >> testAnIndexOnACollectionCreatedInTheSameTransactionIsKept [
	| tx tx2 |
	soil destroy; initializeFilesystem.
	tx := soil newTransaction.
	tx root: (SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		yourself).
	tx root add: (self person: #( 'p01' 'Doe' 'John' )).
	tx root addIndex: (SoilDerivedIndex selector: #lastName).
	tx commit.
	tx2 := soil newTransaction.
	self assert: (self idsOf: ((tx2 root indexFor: #lastName) find: 'Doe')) equals: #( 'p01' ).
	tx2 abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testNewIndexFindsEveryElementInTheTransactionAfterCommitAndAfterReopen [
	| tx tx2 tx3 |
	tx := soil newTransaction.
	tx root add: (self person: #( 'p05' 'Doe' 'Dan' )).
	tx root addIndex: (SoilDerivedIndex selector: #firstName).
	self assert: (self idsOf: ((tx root indexFor: #firstName) find: 'Dan')) equals: #( 'p05' ).
	self assert: (self idsOf: ((tx root indexFor: #firstName) find: 'Pat')) equals: #( 'p04' ).
	self assert: ((tx root indexFor: #firstName) query count) equals: 5.
	tx commit.

	tx2 := soil newTransaction.
	self assert: (self idsOf: ((tx2 root indexFor: #firstName) find: 'Dan')) equals: #( 'p05' ).
	self assert: ((tx2 root indexFor: #firstName) query count) equals: 5.
	tx2 abort.
	soil reopen.
	tx3 := soil newTransaction.
	self assert: (self idsOf: ((tx3 root indexFor: #firstName) find: 'Jane')) equals: #( 'p02' ).
	self assert: ((tx3 root indexFor: #firstName) query count) equals: 5.
	tx3 abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testRaceAAnElementAddedByAnotherTransactionFailsTheBuilder [
	| builder other retry |
	builder := soil newTransaction.
	other := soil newTransaction.
	builder root addIndex: (SoilDerivedIndex selector: #firstName).
	other root add: (self person: #( 'p05' 'Doe' 'Dan' )).
	other commit.
	self should: [ builder commit ] raise: SoilIndexHasConcurrentChange.
	retry := soil newTransaction.
	retry root addIndex: (SoilDerivedIndex selector: #firstName).
	retry commit.
	retry := soil newTransaction.
	self assert: (self idsOf: ((retry root indexFor: #firstName) find: 'Dan')) equals: #( 'p05' ).
	retry abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testRaceAAnElementWrittenByAnotherTransactionFailsTheBuilderToo [
	"no key of the primary changes, but the element the index was built from did"
	| builder other person |
	builder := soil newTransaction.
	other := soil newTransaction.
	builder root addIndex: (SoilDerivedIndex selector: #firstName).
	person := other root at: 'p01'.
	person firstName: 'Johnny'.
	other commit.
	self should: [ builder commit ] raise: SoilIndexHasConcurrentChange
]

{ #category : #tests }
SoilIndexRebuildTest >> testRaceBAWriterThatReadBeforeRemoveIndexFails [
	| writer builder |
	writer := soil newTransaction.
	writer root values.
	builder := soil newTransaction.
	builder root removeIndex: (builder root indexFor: #lastName).
	builder commit.
	writer root add: (self person: #( 'p05' 'Doe' 'Dan' )).
	self should: [ writer commit ] raise: SoilObjectHasConcurrentChange
]

{ #category : #tests }
SoilIndexRebuildTest >> testRaceBAnAddAfterTheIndexWasAddedFailsTheWriter [
	| writer builder retry |
	writer := soil newTransaction.
	writer root values.
	builder := soil newTransaction.
	builder root addIndex: (SoilDerivedIndex selector: #firstName).
	builder commit.
	writer root add: (self person: #( 'p05' 'Doe' 'Dan' )).
	self should: [ writer commit ] raise: SoilObjectHasConcurrentChange.
	retry := soil newTransaction.
	retry root add: (self person: #( 'p05' 'Doe' 'Dan' )).
	retry commit.
	retry := soil newTransaction.
	self assert: (self idsOf: ((retry root indexFor: #firstName) find: 'Dan')) equals: #( 'p05' ).
	retry abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testRaceBRemoveAndUpdateAfterTheIndexWasAddedFailTheWriter [
	| writer builder person |
	writer := soil newTransaction.
	writer root values.
	builder := soil newTransaction.
	builder root addIndex: (SoilDerivedIndex selector: #firstName).
	builder commit.
	writer root remove: (writer root at: 'p01').
	self should: [ writer commit ] raise: SoilObjectHasConcurrentChange.
	writer := soil newTransaction.
	writer root values.
	builder := soil newTransaction.
	builder root removeIndex: (builder root indexFor: #firstName).
	builder commit.
	person := writer root at: 'p02'.
	person lastName: 'Zip'.
	writer root update: person.
	self should: [ writer commit ] raise: SoilObjectHasConcurrentChange
]

{ #category : #tests }
SoilIndexRebuildTest >> testRebuildOfAUniqueIndexFailsOnADoubleValue [
	| tx error |
	tx := soil newTransaction.
	tx root removeIndex: (tx root indexFor: #lastName).
	error := [ tx root addIndex: (SoilDerivedIndex uniqueSelector: #lastName keySize: 16). nil ]
		on: SoilKeyAlreadyPresent
		do: [ :e | e ].
	self assert: error notNil.
	self assert: error indexSelector equals: #lastName.
	self assert: error value equals: 'Doe'.
	self assert: (tx root indexFor: #lastName) isNil.
	self assert: tx root indexes isEmpty.
	tx abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testRebuildThatCannotTakeAValueLeavesNoIndexAndNoEntries [
	| tx index |
	tx := soil newTransaction.
	tx root add: (self person: #( 'p05' 'Moe' nil )).
	index := SoilDerivedIndex selector: #firstName.
	self should: [ tx root addIndex: index ] raise: SoilUnsupportedError.
	self assert: (tx root indexFor: #firstName) isNil.
	self assert: (tx journal entries anySatisfy: [ :each | (each isKindOf: SoilIndexJournalEntry) and: [ each id = index id ] ]) not.
	"other work of the transaction commits"
	tx commit.
	tx := soil newTransaction.
	self assert: (tx root at: 'p05') lastName equals: 'Moe'.
	self assert: (tx root indexFor: #firstName) isNil.
	tx abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testRemoveIndexUnhooksAndRefusesThePrimaryAndAStranger [
	| tx tx2 |
	tx := soil newTransaction.
	self should: [ tx root removeIndex: tx root primaryIndex ] raise: SoilUnsupportedError.
	self should: [ tx root removeIndex: (SoilDerivedIndex selector: #lastName) ] raise: SoilUnsupportedError.
	tx root removeIndex: (tx root indexFor: #lastName).
	self assert: (tx root indexFor: #lastName) isNil.
	tx commit.
	tx2 := soil newTransaction.
	self assert: (tx2 root indexFor: #lastName) isNil.
	self assert: tx2 root indexes isEmpty.
	"a query on the property falls back on the full scan"
	self
		assert: (self idsOf: (tx2 root query property: #lastName; equalTo: 'Doe'; yourself) iterator upToEnd)
		equals: #( 'p01' 'p02' ).
	tx2 abort
]

{ #category : #tests }
SoilIndexRebuildTest >> testTwoOrdinaryWritersDoNotDisturbEachOther [
	| one two tx |
	one := soil newTransaction.
	two := soil newTransaction.
	one root add: (self person: #( 'p05' 'Doe' 'Dan' )).
	two root add: (self person: #( 'p06' 'Roe' 'Ron' )).
	one commit.
	two commit.
	tx := soil newTransaction.
	self assert: tx root values size equals: 6.
	tx abort
]
