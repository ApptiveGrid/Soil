Class {
	#name : #SoilIndexedCollectionTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #helpers }
SoilIndexedCollectionTest >> newCollection [
	^ SoilIndexedCollection new
		addIndex: (SoilDerivedIndex selector: #lastName);
		addIndex: (SoilDerivedIndex selector: #firstName);
		yourself
]

{ #category : #helpers }
SoilIndexedCollectionTest >> newPersonNamed: firstName surname: lastName [
	^ SoilPerson new
		firstName: firstName;
		lastName: lastName;
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
SoilIndexedCollectionTest >> testUniqueIndexUsesTheWholeKeyForTheValue [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: (SoilIndexedCollection new
		addIndex: (SoilDerivedIndex uniqueSelector: #id keySize: 8);
		yourself).
	tx root
		add: ((self newPersonNamed: 'John' surname: 'Doe') id: 'a1'; yourself);
		add: ((self newPersonNamed: 'Jane' surname: 'Doe') id: 'a2'; yourself).
	tx commit.

	tx2 := soil newTransaction.
	self assert: ((tx2 root indexFor: #id) find: 'a2') asArray first firstName equals: 'Jane'.
	self assert: ((tx2 root indexFor: #id) find: 'a') isEmpty.
	tx2 abort
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
