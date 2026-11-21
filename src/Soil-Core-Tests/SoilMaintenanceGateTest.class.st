"
I test locking a database for maintenance: only the process that holds the lock can start transactions and commit, the others are refused.
"
Class {
	#name : #SoilMaintenanceGateTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #private }
SoilMaintenanceGateTest >> commitRoot [
	"a collect needs a root to start from, an empty database has none"
	| tx |
	tx := soil newTransaction.
	tx root: (Dictionary new at: #key put: 1; yourself).
	tx commit
]

{ #category : #private }
SoilMaintenanceGateTest >> inOtherProcess: aBlock [
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
SoilMaintenanceGateTest >> setUp [
	super setUp.
	soil := (Soil new path: 'soil-maintenance-gate-tests')
		destroy;
		initializeFilesystem;
		yourself
]

{ #category : #running }
SoilMaintenanceGateTest >> tearDown [
	super tearDown.
	soil ifNotNil: [ soil close ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testCommitOfAnotherProcessIsRefusedWhileLocked [
	"a transaction that was open when the lock came can still read, but its commit is
	refused: it would write into a database that is being worked on"
	| tx result |
	tx := soil newTransaction.
	tx root: (Dictionary new at: #key put: 1; yourself).
	soil transactionManager closeGate.
	[ result := self inOtherProcess: [ tx commit ].
	  self assert: (result isKindOf: SoilDatabaseLocked).
	  self assert: result holder equals: Processor activeProcess ]
		ensure: [ soil unlockExclusive. tx abort ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testDeadHolderDoesNotKeepTheDatabaseLocked [
	"a process that dies with the lock must not keep everybody out for good"
	| holder |
	holder := [ soil lockExclusive ] newProcess.
	holder resume.
	[ holder isTerminated ] whileFalse: [ Processor yield ].
	self deny: soil isLockedExclusively.
	soil newTransaction abort
]

{ #category : #tests }
SoilMaintenanceGateTest >> testGarbageCollectIsRefusedWhileAnotherProcessHoldsTheLock [
	| result |
	soil lockExclusive.
	[ result := self inOtherProcess: [ soil garbageCollect ].
	  self assert: (result isKindOf: SoilDatabaseLocked) ]
		ensure: [ soil unlockExclusive ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testGarbageCollectUnderMaintenanceDoNests [
	"the lock is the caller's already, so the collect neither fails nor opens the
	database behind the caller's back"
	self commitRoot.
	soil maintenanceDo: [
		soil garbageCollect.
		self assert: soil isLockedExclusively ].
	self deny: soil isLockedExclusively
]

{ #category : #tests }
SoilMaintenanceGateTest >> testGarbageCollectUnlocksTheDatabase [
	self commitRoot.
	soil garbageCollect.
	self deny: soil isLockedExclusively.
	soil newTransaction abort
]

{ #category : #tests }
SoilMaintenanceGateTest >> testHolderCanUseTheDatabaseWhileLocked [
	| tx |
	soil lockExclusive.
	[ tx := soil newTransaction.
	  tx root: (Dictionary new at: #key put: 1; yourself).
	  tx commit ]
		ensure: [ soil unlockExclusive ].
	tx := soil newTransaction.
	[ self assert: (tx root at: #key) equals: 1 ] ensure: [ tx abort ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testLockExclusiveFailsWhileTransactionsAreOpenAndLeavesTheDatabaseOpen [
	| tx error |
	tx := soil newTransaction.
	[ error := [ soil lockExclusive. nil ] on: SoilDatabaseBusy do: [ :e | e ].
	  self assert: (error isKindOf: SoilDatabaseBusy).
	  self assert: error transactions asArray equals: { tx }.
	  self deny: soil isLockedExclusively ]
		ensure: [ tx abort ].
	soil newTransaction abort
]

{ #category : #tests }
SoilMaintenanceGateTest >> testLockExclusiveRefusesNewTransactionsOfAnotherProcess [
	| result |
	soil lockExclusive.
	[ self assert: soil isLockedExclusively.
	  result := self inOtherProcess: [ soil newTransaction ].
	  self assert: (result isKindOf: SoilDatabaseLocked).
	  result := self inOtherProcess: [ soil newReadOnlyTransaction ].
	  self assert: (result isKindOf: SoilDatabaseLocked) ]
		ensure: [ soil unlockExclusive ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testLockExclusiveWaitsForOpenTransactionsToEnd [
	| tx |
	tx := soil newTransaction.
	[ (Delay forMilliseconds: 50) wait.
	  tx abort ] fork.
	soil lockExclusiveWithin: 5 seconds.
	[ self assert: soil isLockedExclusively ]
		ensure: [ soil unlockExclusive ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testLockingTwiceIsRefused [
	soil lockExclusive.
	[ self should: [ soil lockExclusive ] raise: SoilDatabaseLocked.
	  self assert: soil isLockedExclusively ]
		ensure: [ soil unlockExclusive ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testMaintenanceDoUnlocksAfterAnError [
	self
		should: [ soil maintenanceDo: [ self error: 'maintenance failed' ] ]
		raise: Error.
	self deny: soil isLockedExclusively.
	soil newTransaction abort
]

{ #category : #tests }
SoilMaintenanceGateTest >> testUnlockByAnotherProcessIsRefused [
	| result |
	soil lockExclusive.
	[ result := self inOtherProcess: [ soil unlockExclusive ].
	  self assert: (result isKindOf: SoilDatabaseLocked).
	  self assert: soil isLockedExclusively ]
		ensure: [ soil unlockExclusive ]
]

{ #category : #tests }
SoilMaintenanceGateTest >> testUnlockExclusiveOpensTheDatabaseAgain [
	soil lockExclusive.
	soil unlockExclusive.
	self deny: soil isLockedExclusively.
	self assert: (self inOtherProcess: [ soil newTransaction abort. #fine ]) equals: #fine
]
