Class {
	#name : #SoilBehaviorRegistryTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'registry'
	],
	#category : #'Soil-Core-Tests-Model'
}

{ #category : #initialization }
SoilBehaviorRegistryTest >> setUp [ 
	super setUp.
	soil := (Soil path: 'sunit-soil') destroy; initializeFilesystem.
	registry := soil behaviorRegistry
	 
]

{ #category : #running }
SoilBehaviorRegistryTest >> tearDown [ 
	super tearDown.
	soil ifNotNil: [ 
		soil close ]
]

{ #category : #tests }
SoilBehaviorRegistryTest >> testAppendsNewVersionToHistoryCacheAfterCommit [
	"After a new behavior version is committed for a class, a version-history chain
	that was already cached before that commit must be extended in place (the new
	version appended to the front), not dropped and reloaded from disk - see
	SoilTransaction>>updateBehaviorHistoryCachesAfterCommit and
	SoilBehaviorRegistry>>appendCommittedVersion:forIndex:."
	| cls obj tx idx cachedChain sizeBefore |
	cls := (SoilBaseTestObject << #SOBehaviorRegistryAppendTestObject
		layout: FixedLayout;
		slots: { #one. #two };
		package: self class package name) install.
	[
		obj := cls new.
		obj instVarNamed: #one put: 1; instVarNamed: #two put: 2.
		tx := soil newTransaction.
		tx root: obj.
		tx commit.
		idx := (registry nameAt: cls soilBehaviorIdentifier ifAbsent: [ nil ]) index.

		"force the version-history cache to load, simulating a prior read, and keep a
		handle to the exact cached OrderedCollection instance"
		tx := soil newTransaction.
		registry loadHistoryForBehaviorWithIndex: idx transaction: tx.
		tx abort.
		cachedChain := (registry instVarNamed: #versions) at: idx.
		sizeBefore := cachedChain size.

		"changing the shape and committing a new version must extend the SAME cached
		chain object in place, not replace or drop it"
		cls removeSlot: (cls slotNamed: #two); addSlot: #three asSlot.
		obj := cls new.
		obj instVarNamed: #one put: 99.
		tx := soil newTransaction.
		tx root: obj.
		tx commit.

		self assert: ((registry instVarNamed: #versions) at: idx) identicalTo: cachedChain.
		self assert: cachedChain size equals: sizeBefore + 1.
		self assert: cachedChain first isCurrent ]
		ensure: [ cls removeFromSystem ]
]

{ #category : #tests }
SoilBehaviorRegistryTest >> testRegisterNewClass [
	registry nameAt: #Object put: SoilObjectId example.
	self assert: (registry nameAt: #Object ifAbsent: nil) equals: (SoilObjectId example).

]

{ #category : #tests }
SoilBehaviorRegistryTest >> testSOBehaviorDescription [
	"SOBehaviorDescription (the class) itself is always there with index 2"
	self assert: (registry nameAt: #SoilBehaviorDescription ifAbsent: nil) index equals: 2
]
