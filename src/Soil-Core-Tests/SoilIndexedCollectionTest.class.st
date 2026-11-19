Class {
	#name : #SoilIndexedCollectionTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'counter'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilIndexedCollectionTest >> keyTakenIn: aBlock [
	"the SoilKeyAlreadyPresent aBlock signals, fails when it signals none"
	^ [ aBlock value.
		self fail: 'the key should have been refused'.
		nil ]
		on: SoilKeyAlreadyPresent
		do: [ :error | error ]
]

{ #category : #helpers }
SoilIndexedCollectionTest >> newCollection [
	^ SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		addIndex: (SoilDerivedIndex selector: #lastName);
		addIndex: (SoilDerivedIndex selector: #firstName);
		yourself
]

{ #category : #helpers }
SoilIndexedCollectionTest >> newPersonNamed: firstName surname: lastName [
	"the primary key is made up, ascending in the order the persons are made"
	counter := (counter ifNil: [ 0 ]) + 1.
	^ (self newPersonNamed: firstName surname: lastName id: 'p' , counter printString)
]

{ #category : #helpers }
SoilIndexedCollectionTest >> newPersonNamed: firstName surname: lastName id: anId [
	^ SoilPerson new
		firstName: firstName;
		lastName: lastName;
		id: anId;
		yourself
]

{ #category : #accessing }
SoilIndexedCollectionTest >> path [
	^ 'soil-tests'
]

{ #category : #running }
SoilIndexedCollectionTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilIndexedCollectionTest >> tearDown [
	soil ifNotNil: [
		soil close ].
	super tearDown
]

{ #category : #tests }
SoilIndexedCollectionTest >> testAddedObjectIsFoundInAllIndexes [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root add: (self newPersonNamed: 'John' surname: 'Doe').
	tx commit.

	tx2 := soil newTransaction.
	self
		assert: ((tx2 root indexFor: #lastName) values collect: [ :each | each lastName ]) asArray
		equals: #( 'Doe' ).
	self
		assert: ((tx2 root indexFor: #firstName) values collect: [ :each | each firstName ]) asArray
		equals: #( 'John' ).
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testEachIndexIsKeyedByItsOwnSelector [
	"looked up by value, not by position: the order the values come back in says
	nothing about which key they were stored under"
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root
		add: (self newPersonNamed: 'Zoe' surname: 'Adams');
		add: (self newPersonNamed: 'Alice' surname: 'Zimmer').
	tx commit.

	tx2 := soil newTransaction.
	self
		assert: ((tx2 root indexFor: #lastName) find: 'Adams')
			asArray first firstName
		equals: 'Zoe'.
	self
		assert: ((tx2 root indexFor: #firstName) find: 'Alice')
			asArray first lastName
		equals: 'Zimmer'.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testFindAnswersEveryObjectWithTheSameValue [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root
		add: (self newPersonNamed: 'John' surname: 'Doe');
		add: (self newPersonNamed: 'Jane' surname: 'Doe');
		add: (self newPersonNamed: 'Jim' surname: 'Doer').
	tx commit.

	tx2 := soil newTransaction.
	self
		assert: ((tx2 root indexFor: #lastName) find: 'Doe') size
		equals: 2.
	self
		assert: (((tx2 root indexFor: #lastName) find: 'Doe') collect: [ :each | each firstName ]) asSortedCollection asArray
		equals: #( 'Jane' 'John' ).
	self assert: ((tx2 root indexFor: #lastName) find: 'Do') isEmpty.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testFindStaysWithinTheValueAfterReopen [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root
		add: (self newPersonNamed: 'A' surname: 'aa');
		add: (self newPersonNamed: 'B' surname: 'b').
	tx commit.
	soil reopen.

	tx2 := soil newTransaction.
	self assert: ((tx2 root indexFor: #lastName) find: 'aa') size equals: 1.
	self assert: ((tx2 root indexFor: #lastName) find: 'b') size equals: 1.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testAddingAnUnindexableValueIsAnErrorThatNamesIndexAndValue [
	| tx message |
	tx := soil newTransaction.
	tx root: self newCollection.
	message := [ tx root add: (self newPersonNamed: 'John' surname: nil). nil ]
		on: SoilUnsupportedError
		do: [ :error | error messageText ].
	self assert: message equals: 'derived index on #lastName: nil cannot be indexed, let the getter answer a substitute value'.
	tx abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testSurvivesReopeningTheDatabase [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root add: (self newPersonNamed: 'John' surname: 'Doe').
	tx commit.
	"open the database again so nothing is served from cached index structures"
	soil reopen.

	tx2 := soil newTransaction.
	self assert: tx2 root values size equals: 1.
	self assert: tx2 root values first lastName equals: 'Doe'.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testIndexIsConnectedOnFirstUse [
	| tx tx2 derived |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root add: (self newPersonNamed: 'John' surname: 'Doe').
	tx commit.
	soil reopen.

	tx2 := soil newTransaction.
	derived := tx2 root indexFor: #lastName.
	self assert: (derived instVarNamed: 'index') isNil.
	self assert: derived values size equals: 1.
	self assert: (derived instVarNamed: 'index') isNotNil.
	"connected, the id is fixed"
	self should: [ derived id: 'other' ] raise: SoilUnsupportedError.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testIdCanBeSetUntilConnected [
	| tx tx2 derived |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx commit.
	soil reopen.

	tx2 := soil newTransaction.
	derived := tx2 root indexFor: #lastName.
	derived id: 'imported-id'.
	self assert: derived id equals: 'imported-id'.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testKeySizeIsSetPerIndex [
	| narrow wide |
	narrow := SoilDerivedIndex selector: #lastName keySize: 10.
	wide := SoilDerivedIndex selector: #firstName keySize: 24.
	self assert: narrow index keySize equals: 10.
	self assert: wide index keySize equals: 24.
	self assert: (SoilDerivedIndex selector: #id) index keySize equals: 16.
	self assert: (SoilDerivedIndex selector: #id) layout keySize equals: 16.
	self assert: narrow layout attributeSize equals: 2.
	self assert: (SoilDerivedIndex uniqueSelector: #id keySize: 10) layout attributeSize equals: 10.
	self assert: wide index valueSize equals: 8
]

{ #category : #tests }
SoilIndexedCollectionTest >> testPrimaryIsKeptApartFromTheDerivedIndexes [
	| collection tx tx2 |
	collection := self newCollection.
	self assert: collection primaryIndex selector equals: #id.
	self assert: (collection indexes collect: #selector) asArray equals: #( lastName firstName ).
	tx := soil newTransaction.
	tx root: collection.
	tx root
		add: (self newPersonNamed: 'John' surname: 'Doe');
		add: (self newPersonNamed: 'Jane' surname: 'Roe').
	tx commit.

	tx2 := soil newTransaction.
	self assert: tx2 root values size equals: 2.
	self assert: (tx2 root indexFor: #id) id equals: tx2 root primaryIndex id.
	self assert: (tx2 root indexes collect: #selector) asArray equals: #( lastName firstName ).
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testSamePrimaryKeyTwiceInATransactionIsRefusedAndWritesNothing [
	| tx tx2 error |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root add: (self newPersonNamed: 'John' surname: 'Doe' id: 'p1').
	error := self keyTakenIn: [ tx root add: (self newPersonNamed: 'Jane' surname: 'Roe' id: 'p1') ].
	self assert: error indexSelector equals: #id.
	self assert: error value equals: 'p1'.
	tx commit.

	tx2 := soil newTransaction.
	self assert: tx2 root values size equals: 1.
	self assert: ((tx2 root indexFor: #lastName) find: 'Roe') isEmpty.
	self assert: ((tx2 root indexFor: #firstName) find: 'Jane') isEmpty.
	self assert: ((tx2 root indexFor: #lastName) find: 'Doe') size equals: 1.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testSamePrimaryKeyAsACommittedElementIsRefused [
	| tx tx2 error |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root add: (self newPersonNamed: 'John' surname: 'Doe' id: 'p1').
	tx commit.

	tx2 := soil newTransaction.
	error := self keyTakenIn: [ tx2 root add: (self newPersonNamed: 'Jane' surname: 'Roe' id: 'p1') ].
	self assert: error indexSelector equals: #id.
	self assert: error value equals: 'p1'.
	self assert: ((tx2 root indexFor: #lastName) find: 'Roe') isEmpty.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testSamePrimaryKeyInTwoTransactionsFailsTheSecondCommit [
	| tx1 tx2 |
	tx1 := soil newTransaction.
	tx1 root: self newCollection.
	tx1 commit.

	tx1 := soil newTransaction.
	tx2 := soil newTransaction.
	tx1 root add: (self newPersonNamed: 'John' surname: 'Doe' id: 'p1').
	tx2 root add: (self newPersonNamed: 'Jane' surname: 'Roe' id: 'p1').
	tx1 commit.
	self should: [ tx2 commit ] raise: SoilIndexHasConcurrentChange
]

{ #category : #tests }
SoilIndexedCollectionTest >> testValueThatCannotBeIndexedFailsBeforeAnythingIsWritten [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	self
		should: [ tx root add: (self newPersonNamed: 'John' surname: nil) ]
		raise: SoilUnsupportedError.
	self
		should: [ tx root add: (self newPersonNamed: nil surname: 'Doe') ]
		raise: SoilUnsupportedError.
	tx commit.

	tx2 := soil newTransaction.
	self assert: tx2 root values isEmpty.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testTwoNewObjectsWithTheSameAttributeAreBothSeenInTheTransactionAfterCommitAndAfterReopen [
	| tx tx2 tx3 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root
		add: (self newPersonNamed: 'John' surname: 'Doe');
		add: (self newPersonNamed: 'Jane' surname: 'Doe').
	self assert: ((tx root indexFor: #lastName) find: 'Doe') size equals: 2.
	tx commit.

	tx2 := soil newTransaction.
	self assert: ((tx2 root indexFor: #lastName) find: 'Doe') size equals: 2.
	tx2 abort.
	soil reopen.

	tx3 := soil newTransaction.
	self assert: ((tx3 root indexFor: #lastName) find: 'Doe') size equals: 2.
	tx3 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testEqualAttributesAnswerInPrimaryKeyOrder [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	#( 'p3' 'p1' 'p2' ) do: [ :id |
		tx root add: (self newPersonNamed: 'N' , id surname: 'Doe' id: id) ].
	tx commit.

	tx2 := soil newTransaction.
	self
		assert: (((tx2 root indexFor: #lastName) find: 'Doe') collect: [ :each | each id ]) asArray
		equals: #( 'p1' 'p2' 'p3' ).
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testUniqueDerivedIndexRefusesASecondElementWithTheSameValue [
	| tx tx2 error |
	tx := soil newTransaction.
	tx root: (SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		addIndex: (SoilDerivedIndex uniqueSelector: #lastName keySize: 16);
		yourself).
	tx root add: (self newPersonNamed: 'John' surname: 'Doe').
	error := self keyTakenIn: [ tx root add: (self newPersonNamed: 'Jane' surname: 'Doe') ].
	self assert: error indexSelector equals: #lastName.
	self assert: error value equals: 'Doe'.
	self assert: error messageText equals: 'derived index on #lastName: another element has the value ''Doe'' already'.
	tx root add: (self newPersonNamed: 'Jane' surname: 'Roe').
	tx commit.

	tx2 := soil newTransaction.
	self assert: tx2 root values size equals: 2.
	self assert: ((tx2 root indexFor: #lastName) find: 'Doe') size equals: 1.
	tx2 abort
]

{ #category : #tests }
SoilIndexedCollectionTest >> testDerivedIndexNeedsRoomBesideThePrimaryKey [
	| collection |
	collection := SoilIndexedCollection new
		primary: (SoilDerivedIndex uniqueSelector: #id keySize: 12);
		yourself.
	self
		should: [ collection addIndex: (SoilDerivedIndex selector: #lastName keySize: 12) ]
		raise: SoilUnsupportedError.
	self shouldnt: [ collection addIndex: (SoilDerivedIndex selector: #lastName keySize: 13) ] raise: Error
]

{ #category : #tests }
SoilIndexedCollectionTest >> testNoDerivedIndexBeforeThePrimary [
	self
		should: [ SoilIndexedCollection new addIndex: (SoilDerivedIndex selector: #lastName) ]
		raise: SoilUnsupportedError
]

{ #category : #tests }
SoilIndexedCollectionTest >> testPrimaryCannotBeAddedAsADerivedIndex [
	| collection |
	collection := self newCollection.
	self
		should: [ collection addIndex: collection primaryIndex ]
		raise: SoilUnsupportedError
]
