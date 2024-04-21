Class {
	#name : #SoilCyclicObjectGraphTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilCyclicObjectGraphTest class >> classNamesNotUnderTest [
	"we for now ignore flock as this is platform specific"
	^ #(#MacOSFileLock #UnixFileLock)
]

{ #category : #accessing }
SoilCyclicObjectGraphTest class >> packageNamesUnderTest [
	^ #(#'Soil-Core')
]

{ #category : #accessing }
SoilCyclicObjectGraphTest >> path [ 
	^ 'soil-tests' asFileReference
]

{ #category : #initialization }
SoilCyclicObjectGraphTest >> setUp [

	| txn |
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	txn := soil newTransaction.
	txn root: SoilPersistentDictionary new.
	txn commit
]

{ #category : #running }
SoilCyclicObjectGraphTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilCyclicObjectGraphTest >> testCyclicGraph [

	| o1 o2 txn |
	o1 := Set new.
	o2 := Set new.
	o1 add: o2.
	o2 add: o1.

	txn := soil newTransaction.
	txn root
		at: #o1 put: o1;
		at: #o2 put: o2.
	txn
		markDirty: o1;
		markDirty: o2;
		commit.

	txn := soil newTransaction.

	self
		assert: ((txn root at: #o1) includes: (txn root at: #o2));
		assert: ((txn root at: #o2) includes: (txn root at: #o1))
]

{ #category : #tests }
SoilCyclicObjectGraphTest >> testSimpleGraph [

	| o1 o2 txn |
	o1 := Set new.
	o2 := Set new.
	o1 add: o2.
	"o2 add: o1."

	txn := soil newTransaction.
	txn root
		at: #o1 put: o1;
		at: #o2 put: o2.
	txn
		markDirty: o1;
		markDirty: o2;
		commit.

	txn := soil newTransaction.

	self
		assert: ((txn root at: #o1) includes: (txn root at: #o2));
		assert: (txn root at: #o2) isEmpty
]
