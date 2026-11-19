Class {
	#name : #SoilCommitValidationTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests-Transaction'
}

{ #category : #helpers }
SoilCommitValidationTest >> commitRootWith: aNumber [
	| tx |
	tx := soil newTransaction.
	tx root: (SoilPersistentDictionary new at: #n put: aNumber; yourself).
	tx commit
]

{ #category : #accessing }
SoilCommitValidationTest >> path [
	^ 'soil-tests'
]

{ #category : #running }
SoilCommitValidationTest >> setUp [
	super setUp.
	soil := Soil path: self path.
	soil
		destroy;
		initializeFilesystem.
	self commitRootWith: 1
]

{ #category : #running }
SoilCommitValidationTest >> tearDown [
	soil ifNotNil: [ soil close ].
	super tearDown
]

{ #category : #tests }
SoilCommitValidationTest >> testAFailingValidationLeavesNothingWrittenAndTheLocksFree [
	| tx probe tx2 tx3 |
	tx := soil newTransaction.
	probe := SoilCommitValidationProbe new beFailing; yourself.
	tx addCommitValidation: probe.
	tx root at: #n put: 99.
	self should: [ tx commit ] raise: SoilIndexHasConcurrentChange.
	"nothing was written"
	tx2 := soil newTransaction.
	self assert: (tx2 root at: #n) equals: 1.
	"and the locks are free: another commit goes through"
	tx2 root at: #n put: 3.
	tx2 commit.
	tx3 := soil newTransaction.
	self assert: (tx3 root at: #n) equals: 3.
	tx3 abort
]

{ #category : #tests }
SoilCommitValidationTest >> testATransactionWithoutChangesDoesNotRunItAndDoesNotFail [
	| tx probe |
	tx := soil newTransaction.
	probe := SoilCommitValidationProbe new beFailing; yourself.
	tx addCommitValidation: probe.
	tx root at: #n.
	tx commit.
	self assert: probe runs equals: 0
]

{ #category : #tests }
SoilCommitValidationTest >> testAValidationRunsWhenATransactionWithChangesCommits [
	| tx probe |
	tx := soil newTransaction.
	probe := SoilCommitValidationProbe new.
	tx addCommitValidation: probe.
	tx root at: #n put: 2.
	tx commit.
	self assert: probe runs equals: 1
]

{ #category : #tests }
SoilCommitValidationTest >> testAnEqualValidationIsRunOnce [
	| tx probe |
	tx := soil newTransaction.
	probe := SoilCommitValidationProbe new.
	tx addCommitValidation: probe.
	tx addCommitValidation: probe.
	tx root at: #n put: 2.
	tx commit.
	self assert: probe runs equals: 1
]

{ #category : #tests }
SoilCommitValidationTest >> testTheErrorOfAValidationReachesTheCommitter [
	| tx seen |
	tx := soil newTransaction.
	seen := nil.
	tx addCommitValidation: (SoilCommitValidationProbe new
		beFailing;
		yourself).
	tx root at: #n put: 5.
	[ tx commit ] on: SoilIndexHasConcurrentChange do: [ :error | seen := error indexId ].
	self assert: seen equals: 'probe'
]
