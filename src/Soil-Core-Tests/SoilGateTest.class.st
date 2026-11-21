"
I test the gate of a database: while it is closed, only the process that closed it can start transactions and commit, the others are refused.
"
Class {
	#name : #SoilGateTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #private }
SoilGateTest >> commitRoot [
	"a collect needs a root to start from, an empty database has none"
	| tx |
	tx := soil newTransaction.
	tx root: (Dictionary new at: #key put: 1; yourself).
	tx commit
]

{ #category : #private }
SoilGateTest >> inOtherProcess: aBlock [
	"evaluate aBlock in a process of its own and answer its value, or the error it
	signalled, so that the test can look at what the other process was told"
	| result done |
	done := Semaphore new.
	[ result := [ aBlock value ] on: Error do: [ :error | error ].
	  done signal ] fork.
	done wait.
	^ result
]

{ #category : #running }
SoilGateTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-gate-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilGateTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilGateTest >> testClosingTwiceIsRefused [
	soil closeGate.
	[ self should: [ soil closeGate ] raise: SoilGateClosed.
	  self assert: soil isGateClosed ]
		ensure: [ soil openGate ]
]

{ #category : #tests }
SoilGateTest >> testCommitOfAnotherProcessIsRefusedWhileClosed [
	"a transaction that was open when the gate closed can still read, but its commit is
	refused: it would write into a database that is being worked on"
	| tx result |
	tx := soil newTransaction.
	tx root: (Dictionary new at: #key put: 1; yourself).
	soil closeGate.
	[ result := self inOtherProcess: [ tx commit ].
	  self assert: (result isKindOf: SoilGateClosed).
	  self assert: result holder equals: Processor activeProcess ]
		ensure: [ soil openGate. tx abort ]
]

{ #category : #tests }
SoilGateTest >> testDeadHolderDoesNotKeepTheGateClosed [
	"a process that dies with the gate closed must not keep everybody out for good"
	| holder |
	holder := [ soil closeGate ] newProcess.
	holder resume.
	[ holder isTerminated ] whileFalse: [ Processor yield ].
	self deny: soil isGateClosed.
	soil newTransaction abort
]

{ #category : #tests }
SoilGateTest >> testDrainFailsWhileTransactionsAreOpenAndLeavesTheGateOpen [
	| tx error |
	tx := soil newTransaction.
	[ error := [ soil closeGateAndDrainWithin: 0 seconds. nil ]
		on: SoilDatabaseBusy do: [ :e | e ].
	  self assert: (error isKindOf: SoilDatabaseBusy).
	  self assert: error transactions asArray equals: { tx }.
	  self deny: soil isGateClosed ]
		ensure: [ tx abort ].
	soil newTransaction abort
]

{ #category : #tests }
SoilGateTest >> testDrainWaitsForOpenTransactionsToEnd [
	| tx |
	tx := soil newTransaction.
	[ (Delay forMilliseconds: 50) wait.
	  tx abort ] fork.
	soil closeGateAndDrainWithin: 5 seconds.
	[ self assert: soil isGateClosed ]
		ensure: [ soil openGate ]
]

{ #category : #tests }
SoilGateTest >> testDrainedGateDoOpensAfterAnError [
	self
		should: [ soil drainedGateDo: [ self error: 'maintenance failed' ] ]
		raise: Error.
	self deny: soil isGateClosed.
	soil newTransaction abort
]

{ #category : #tests }
SoilGateTest >> testGarbageCollectIsRefusedWhileAnotherProcessHoldsTheGate [
	| result |
	soil closeGate.
	[ result := self inOtherProcess: [ soil garbageCollect ].
	  self assert: (result isKindOf: SoilGateClosed) ]
		ensure: [ soil openGate ]
]

{ #category : #tests }
SoilGateTest >> testGarbageCollectOpensTheGateAgain [
	self commitRoot.
	soil garbageCollect.
	self deny: soil isGateClosed.
	soil newTransaction abort
]

{ #category : #tests }
SoilGateTest >> testGarbageCollectUnderDrainedGateDoNests [
	"the gate is the caller's already, so the collect neither fails nor opens it behind
	the caller's back"
	self commitRoot.
	soil drainedGateDo: [
		soil garbageCollect.
		self assert: soil isGateClosed ].
	self deny: soil isGateClosed
]

{ #category : #tests }
SoilGateTest >> testHolderCanUseTheDatabaseWhileClosed [
	| tx |
	soil closeGate.
	[ tx := soil newTransaction.
	  tx root: (Dictionary new at: #key put: 1; yourself).
	  tx commit ]
		ensure: [ soil openGate ].
	tx := soil newTransaction.
	[ self assert: (tx root at: #key) equals: 1 ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilGateTest >> testOpenByAnotherProcessIsRefused [
	| result |
	soil closeGate.
	[ result := self inOtherProcess: [ soil openGate ].
	  self assert: (result isKindOf: SoilGateClosed).
	  self assert: soil isGateClosed ]
		ensure: [ soil openGate ]
]

{ #category : #tests }
SoilGateTest >> testOpenGateOpensTheDatabaseAgain [
	soil closeGate.
	soil openGate.
	self deny: soil isGateClosed.
	self assert: (self inOtherProcess: [ soil newTransaction abort. #fine ]) equals: #fine
]

{ #category : #tests }
SoilGateTest >> testOtherProcessesGetNoNewTransactions [
	| result |
	soil closeGate.
	[ self assert: soil isGateClosed.
	  result := self inOtherProcess: [ soil newTransaction ].
	  self assert: (result isKindOf: SoilGateClosed).
	  result := self inOtherProcess: [ soil newReadOnlyTransaction ].
	  self assert: (result isKindOf: SoilGateClosed) ]
		ensure: [ soil openGate ]
]
