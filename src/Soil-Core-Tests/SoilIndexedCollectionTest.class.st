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
		addIndex: (SoilObjectIndex new
			selector: #lastName;
			indexClass: SoilSkipList;
			yourself);
		addIndex: (SoilObjectIndex new
			selector: #firstName;
			indexClass: SoilSkipList;
			yourself);
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
SoilIndexedCollectionTest >> testIndexesAreOrderedByTheirOwnKey [
	| tx tx2 |
	tx := soil newTransaction.
	tx root: self newCollection.
	tx root
		add: (self newPersonNamed: 'Zoe' surname: 'Adams');
		add: (self newPersonNamed: 'Alice' surname: 'Zimmer').
	tx commit.

	tx2 := soil newTransaction.
	self
		assert: ((tx2 root indexFor: #lastName) values collect: [ :each | each lastName ]) asArray
		equals: #( 'Adams' 'Zimmer' ).
	self
		assert: ((tx2 root indexFor: #firstName) values collect: [ :each | each firstName ]) asArray
		equals: #( 'Alice' 'Zoe' ).
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
