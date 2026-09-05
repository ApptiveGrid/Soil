"
What a detached object is for: living on after the transaction it came from is
gone. Every test here closes that transaction before it asks anything, because
that is the whole claim -- a SoilObjectProxy would fail at exactly this point.

The object I detach is a plain one, SoilTestClusterRoot, and that is not an
accident. A Soil-managed collection is only half detachable: reading from a
detached SoilPersistentDictionary works after its transaction is gone, because
#at:ifAbsent: goes straight to the inner dictionary, but writing does not --
#at:put: has to make every stored value a cluster root, and that needs a
transaction. So the shape that detaches cleanly today is what is a plain object
once materialized, which is exactly the real case: a limits object with ivars.
"
Class {
	#name : #SoilDetachedObjectTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helpers }
SoilDetachedObjectTest >> detachedFullyFrom: aBlock [
	"mint a fully detached object inside a transaction and leave that transaction
	behind -- aborted, gone, nothing to resolve through afterwards"
	| txn detached |
	txn := soil newTransaction.
	detached := SoilFullyDetachedObject on: (aBlock value: txn) in: txn.
	txn abort.
	^ detached
]

{ #category : #accessing }
SoilDetachedObjectTest >> path [
	^ 'soil-detached-object-tests'
]

{ #category : #running }
SoilDetachedObjectTest >> setUp [
	| txn kept |
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	txn := soil newTransaction.
	txn root: SoilPersistentDictionary new.
	txn commit.
	txn := soil newTransaction.
	kept := SoilTestClusterRoot new nested: 1; yourself.
	txn makeRoot: kept.
	txn root at: #kept put: kept.
	txn commit
]

{ #category : #running }
SoilDetachedObjectTest >> tearDown [
	soil ifNotNil: [
		soil close.
		soil destroy ].
	super tearDown
]

{ #category : #tests }
SoilDetachedObjectTest >> testAProxyAndADetachedHandleOnTheSameObjectAreIdentical [
	"and in both directions -- an asymmetric identity would be worse than none"
	| txn proxy detached |
	txn := soil newTransaction.
	proxy := txn root at: #kept.
	detached := SoilFullyDetachedObject on: proxy in: txn.
	self assert: proxy isSoilProxy.

	self assert: (detached isIdenticalTo: proxy).
	self assert: (proxy isIdenticalTo: detached).
	txn abort
]

{ #category : #tests }
SoilDetachedObjectTest >> testComparingWithAnUnrelatedObjectStaysFalse [
	| detached |
	detached := self detachedFullyFrom: [ :txn | txn root at: #kept ].
	self deny: (detached isIdenticalTo: SoilTestClusterRoot new).
	self deny: (detached isEqualTo: SoilTestClusterRoot new)
]

{ #category : #tests }
SoilDetachedObjectTest >> testTwoDetachedHandlesOnTheSameObjectAreIdentical [
	"the case that shows why the objectId is the criterion and the materialized
	object is not: each transaction materializes its own, so #== falls apart while
	the id does not"
	| first second |
	first := self detachedFullyFrom: [ :txn | txn root at: #kept ].
	second := self detachedFullyFrom: [ :txn | txn root at: #kept ].

	self assert: first objectId equals: second objectId.
	self deny: first soilRealObject == second soilRealObject.

	self assert: (first isIdenticalTo: second).
	self assert: (second isIdenticalTo: first).
	self assert: (first isEqualTo: second)
]

{ #category : #tests }
SoilDetachedObjectTest >> testRecognisesItsOwnMaterializationButNotAForeignOne [
	"the objectId decides only where the other side stands in for a stored object
	too. A plain object carries none, so all that is left to compare against is
	the materialization I hold -- and another transaction's copy of the same
	stored object is a different object. SoilObjectProxy answers true here
	because what it unwraps to is its own; a detached handle cannot, and that is
	the price of holding a materialization instead of resolving one. Asking a
	transaction mid-comparison would pay it, and reading never opens one."
	| detached foreign txn |
	detached := self detachedFullyFrom: [ :mintingTxn | mintingTxn root at: #kept ].
	self assert: (detached isIdenticalTo: detached soilRealObject).

	txn := soil newTransaction.
	foreign := (txn root at: #kept) theNonSoilProxy.
	self assert: detached objectId equals: (txn objectIdOf: foreign).
	self deny: (detached isIdenticalTo: foreign).
	txn abort
]

{ #category : #tests }
SoilDetachedObjectTest >> testAnswersFromTheHeldObjectWithoutATransaction [
	"the claim in one line: the minting transaction is gone, and sends still work"
	| detached |
	detached := self detachedFullyFrom: [ :txn | txn root at: #kept ].
	self assert: detached nested equals: 1
]

{ #category : #tests }
SoilDetachedObjectTest >> testChangedDoesNothingOnItsOwn [
	"the fully detached one only offers the hook; giving it a meaning is the
	subclasses' business"
	| detached |
	detached := self detachedFullyFrom: [ :txn | txn root at: #kept ].
	detached changed.
	self assert: detached nested equals: 1
]

{ #category : #tests }
SoilDetachedObjectTest >> testKeepsTheObjectIdItWasMintedWith [
	"the id is what makes a later write-back possible without searching again"
	| txn detached expected |
	txn := soil newTransaction.
	expected := txn objectIdOf: (txn root at: #kept).
	detached := SoilFullyDetachedObject on: (txn root at: #kept) in: txn.
	txn abort.
	self assert: detached objectId equals: expected
]

{ #category : #tests }
SoilDetachedObjectTest >> testMutationStaysLocalUntilSomebodyWritesItBack [
	"the fully detached one cannot write, so a change to the held object is not in
	the store -- this is what the resident's grace period buys, and why the write
	has to be somebody's job"
	| detached txn |
	detached := self detachedFullyFrom: [ :txn2 | txn2 root at: #kept ].
	detached nested: 42.
	self assert: detached nested equals: 42.
	txn := soil newTransaction.
	self assert: ([ (txn root at: #kept) nested ] ensure: [ txn abort ]) equals: 1
]

{ #category : #tests }
SoilDetachedObjectTest >> testWriteBackPutsTheObjectBackAtItsId [
	"the one thing the database gives me: a transaction of my own, on demand and
	named, not as a side effect of some forwarded send"
	| txn detached readBack |
	txn := soil newTransaction.
	detached := SoilDetachedObject on: (txn root at: #kept) in: txn.
	txn abort.

	detached nested: 42.
	detached writeBack.

	txn := soil newTransaction.
	readBack := [ (txn root at: #kept) nested ] ensure: [ txn abort ].
	self assert: readBack equals: 42
]

{ #category : #tests }
SoilDetachedObjectTest >> testWriteBackTakesItsDatabaseFromTheMintingTransaction [
	| txn detached |
	txn := soil newTransaction.
	detached := SoilDetachedObject on: (txn root at: #kept) in: txn.
	txn abort.
	self assert: detached soil identicalTo: soil
]
