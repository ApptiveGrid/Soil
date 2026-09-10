"
The acceptance criterion of the generic base: a dummy resident starts, works,
acknowledges a requestStop, and on failure leaves the other residents
untouched -- all of it without any embedder's registry of open databases.
"
Class {
	#name : #SoilResidentTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #helpers }
SoilResidentTest >> addResident: aDescription [
	^ soil addResidentDescription: aDescription
]

{ #category : #accessing }
SoilResidentTest >> path [
	^ 'soil-resident-tests'
]

{ #category : #helpers }
SoilResidentTest >> residentRegistryObjectId [
	| txn |
	txn := soil newTransaction.
	^ [ txn objectIdOf: (soil residentRegistryIn: txn) ]
		ensure: [ txn abort ]
]

{ #category : #helpers }
SoilResidentTest >> restart: aSupervisor resident: aSymbol within: aDuration [
	"like #stop:within:, the embedder's transaction stays reading and is discarded:
	a resident reads its configuration in it and opens its own to write"
	| txn |
	txn := soil newTransaction.
	^ [ aSupervisor restartResidentNamed: aSymbol in: txn timeout: aDuration ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ]
]

{ #category : #running }
SoilResidentTest >> setUp [
	super setUp.
	soil := SoilTestResidentDatabase path: self path.
	soil
		destroy;
		initializeFilesystem;
		initializeRoot
]

{ #category : #helpers }
SoilResidentTest >> startedSupervisor [
	"what an embedder does on open: create all instances first, start them
	afterwards"
	| supervisor txn |
	supervisor := soil newResidentSupervisor.
	txn := soil newTransaction.
	[ supervisor loadFrom: txn.
	supervisor startAllIn: txn tickEvery: 1 hour reportEvery: 1 hour ]
		ensure: [ txn abort ].
	^ supervisor
]

{ #category : #helpers }
SoilResidentTest >> stop: aSupervisor within: aDuration [
	"the embedder's stop transaction stays reading and is discarded -- a resident
	that has to write opens its own"
	| txn |
	txn := soil newTransaction.
	^ [ aSupervisor stopAllIn: txn timeout: aDuration ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ]
]

{ #category : #running }
SoilResidentTest >> tearDown [
	soil ifNotNil: [
		soil close.
		soil destroy ].
	super tearDown
]

{ #category : #tests }
SoilResidentTest >> testAddingATakenNameIsRefused [
	"the resident already here may be started and holding a process; replacing it
	silently would leave it running and unreachable"
	| supervisor |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	self
		should: [ supervisor addResident: SoilTestResident new ]
		raise: SoilResidentAlreadyPresent.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testAnswerErrorsAreIsolatedAndCountAsBusy [
	"a resident that throws on an answer must not drag the others along, and an
	answer we could not get counts in the direction that keeps the database open"
	| supervisor |
	self addResident: SoilTestThrowingResidentDescription new.
	self addResident: SoilTestPassiveResidentDescription new.
	supervisor := self startedSupervisor.

	self deny: supervisor isIdle.
	self assert: supervisor hasPendingWork.
	"the passive one is untouched and still answers for itself"
	self assert: (supervisor residentNamed: #passive) isIdle
]

{ #category : #tests }
SoilResidentTest >> testDummyResidentBlocksAndReleasesIdle [
	"the point of the whole exercise: while a work unit runs, the resident says
	it is not idle, and afterwards it says it is again"
	| supervisor resident |
	self addResident: (SoilTestResidentDescription new workDuration: 300 milliSeconds).
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.
	self assert: supervisor isIdle.
	self deny: supervisor hasPendingWork.

	resident triggerWork.
	"the flag is set synchronously by the signalling process, so there is no
	window here in which the supervisor would report idle"
	self deny: supervisor isIdle.
	self assert: supervisor hasPendingWork.

	self waitUntil: [ resident stepCount = 1 ] within: 5 seconds.
	self waitUntil: [ supervisor isIdle ] within: 1 second.
	self deny: supervisor hasPendingWork.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testEnsureTickProcessRevivesATerminatedTick [
	"a process cannot revive itself once it is gone, so somebody from outside has
	to look"
	| supervisor |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	supervisor startTickEvery: 10 seconds reportEvery: 1 hour.
	self assert: supervisor tickProcessIsRunning.

	supervisor tickProcess terminate.
	self deny: supervisor tickProcessIsRunning.
	supervisor ensureTickProcess.
	self assert: supervisor tickProcessIsRunning.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testEnsureTickProcessStaysQuietWithoutAnInterval [
	"without an interval there is no tick to keep alive"
	| supervisor |
	supervisor := self startedSupervisor.
	supervisor ensureTickProcess.
	self deny: supervisor tickProcessIsRunning
]

{ #category : #tests }
SoilResidentTest >> testFailedResidentReportsIdleAndNoPendingWork [
	"a failed resident must not block a decision it can no longer influence"
	| supervisor failing |
	self addResident: SoilTestFailingResidentDescription new.
	supervisor := self startedSupervisor.
	failing := supervisor residentNamed: #failing.
	self assert: failing hasFailed.
	self assert: failing isIdle.
	self deny: failing hasPendingWork
]

{ #category : #tests }
SoilResidentTest >> testFailingResidentLeavesOthersUntouched [
	"errors are isolated per resident, and the failure is left behind visibly
	rather than merely logged -- the embedder needs the answer to decide"
	| supervisor failing dummy |
	self addResident: SoilTestFailingResidentDescription new.
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.

	failing := supervisor residentNamed: #failing.
	dummy := supervisor residentNamed: #dummy.
	self assert: failing hasFailed.
	self assert: failing error messageText equals: 'deliberately failing to start'.
	self assert: dummy isStarted.
	self assert: dummy hasRunningProcess.
	self
		assertCollection: (supervisor failedResidents collect: [ :each | each name ])
		hasSameElements: #( failing ).
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testFlushErrorsAreIsolated [
	"a failed flush of one resident must not cost the others theirs"
	| supervisor passive txn flushed |
	self addResident: SoilTestThrowingResidentDescription new.
	self addResident: SoilTestPassiveResidentDescription new.
	supervisor := self startedSupervisor.
	passive := supervisor residentNamed: #passive.
	passive book; book.

	self stop: supervisor within: 5 seconds.

	txn := soil newTransaction.
	flushed := [ ((soil residentRegistryIn: txn) descriptionNamed: #passive) workspace at: #flushed ]
		ensure: [ txn abort ].
	self assert: flushed equals: 2
]

{ #category : #tests }
SoilResidentTest >> testHangingResidentIsTerminatedAfterTimeout [
	"the deliberate hard way out: without it a hanging resident would keep the
	image from quitting"
	| supervisor pending hanging |
	self addResident: SoilTestHangingResidentDescription new.
	supervisor := self startedSupervisor.
	hanging := supervisor residentNamed: #hanging.
	self assert: hanging hasRunningProcess.

	pending := self stop: supervisor within: 200 milliSeconds.
	self
		assertCollection: (pending collect: [ :each | each name ])
		hasSameElements: #( hanging ).
	self assert: hanging isStopped.
	self deny: hanging hasRunningProcess
]

{ #category : #tests }
SoilResidentTest >> testLoadingTwiceIsRefused [
	"a second load would build a second set of instances while the first set is
	started and holding processes"
	| supervisor txn |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	txn := soil newTransaction.
	[ self
		should: [ supervisor loadFrom: txn ]
		raise: SoilResidentsAlreadyLoaded ]
		ensure: [ txn abort ].
	self assert: supervisor residents size equals: 1.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testNoTickWhileStopped [
	| supervisor resident before |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.
	before := resident tickCount.

	resident requestStop.
	self waitUntil: [ resident isStopped ] within: 5 seconds.
	supervisor tick.
	self assert: resident tickCount equals: before
]

{ #category : #tests }
SoilResidentTest >> testNoTickWhileStopping [
	"otherwise the tick starts up again what the stop is just clearing away"
	| supervisor hanging before |
	self addResident: SoilTestHangingResidentDescription new.
	supervisor := self startedSupervisor.
	hanging := supervisor residentNamed: #hanging.
	before := hanging tickCount.

	"it ignores the flag, so it stays in #stopping"
	hanging requestStop.
	self assert: hanging isStopping.
	supervisor tick.
	self assert: hanging tickCount equals: before
]

{ #category : #tests }
SoilResidentTest >> testPassiveResidentFlushesOnStop [
	"the only case in which a resident does work while stopping: state collected
	in memory has to go out instead of being discarded"
	| supervisor passive txn flushed |
	self addResident: SoilTestPassiveResidentDescription new.
	supervisor := self startedSupervisor.
	passive := supervisor residentNamed: #passive.
	passive
		book;
		book;
		book.

	self stop: supervisor within: 5 seconds.

	txn := soil newTransaction.
	flushed := [ ((soil residentRegistryIn: txn) descriptionNamed: #passive) workspace at: #flushed ]
		ensure: [ txn abort ].
	self assert: flushed equals: 3
]

{ #category : #tests }
SoilResidentTest >> testPassiveResidentStopsWithoutProcess [
	"nobody would notice the flag, so requestStop has to take it to stopped right
	away"
	| supervisor passive |
	self addResident: SoilTestPassiveResidentDescription new.
	supervisor := self startedSupervisor.
	passive := supervisor residentNamed: #passive.
	self deny: passive hasRunningProcess.
	passive requestStop.
	self assert: passive isStopped
]

{ #category : #tests }
SoilResidentTest >> testRegistryIsClusterRootWithStableObjectId [
	"deliberately a cluster root of its own from stage one, so named roots later
	only add a name -> object id entry instead of moving data in databases in
	production"
	| first second |
	self addResident: SoilTestResidentDescription new.
	first := self residentRegistryObjectId.
	self addResident: SoilTestPassiveResidentDescription new.
	second := self residentRegistryObjectId.
	self assert: first equals: second
]

{ #category : #tests }
SoilResidentTest >> testResidentNamedSignalsWhenAbsent [
	| supervisor |
	supervisor := self startedSupervisor.
	self
		should: [ supervisor residentNamed: #nothingHere ]
		raise: SoilResidentNotFound
]

{ #category : #tests }
SoilResidentTest >> testRestartingAnUnknownNameSignals [
	"an embedder asking to restart something that is not here has the wrong name,
	and a silent no is how that stays unnoticed"
	| supervisor |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.

	self
		should: [ self restart: supervisor resident: #nosuchresident within: 5 seconds ]
		raise: SoilResidentNotFound.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testRestartingBringsAFailedResidentBack [
	"the way back: a resident that #failed -- at its first start or through a later
	guard -- is startable again, and its start really runs"
	| supervisor resident |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.
	resident markFailed: (Error new messageText: 'put here by the test').
	self assert: resident hasFailed.

	self restart: supervisor resident: #dummy within: 5 seconds.
	self assert: resident isStarted.
	self deny: resident hasFailed.
	self assert: resident startCount equals: 2.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testRestartingClearsTheStopFlagSoWorkGoesOn [
	"the trap this exists to avoid: the stop flag survives a stop, and a loop
	started with it still up leaves at its first check and marks itself stopped
	again -- a restart that reports success and started nothing"
	| supervisor resident |
	self addResident: SoilTestActiveResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #active.

	self restart: supervisor resident: #active within: 5 seconds.
	self assert: resident isStarted.
	self deny: resident shouldStop.
	resident noteWork.
	self assert: (resident waitForStepWithin: 5 seconds).
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testRestartingReadsTheConfigurationAgain [
	"what the whole call is for: #prepareIn: is where a resident reads its
	description, so a second run of it is the observable that the new configuration
	arrived"
	| supervisor resident |
	self addResident: SoilTestActiveResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #active.
	self assert: resident prepareCount equals: 1.

	self
		assert: (self restart: supervisor resident: #active within: 5 seconds)
		identicalTo: resident.
	self assert: resident prepareCount equals: 2.
	self assert: resident isStarted.
	self assert: resident hasRunningProcess.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testStoppingAHangingResidentReportsTheHardWayOut [
	"false means the receipt did not arrive and the process was terminated after
	all -- the same deliberate exit the group stop takes"
	| supervisor hanging |
	self addResident: SoilTestHangingResidentDescription new.
	supervisor := self startedSupervisor.
	hanging := supervisor residentNamed: #hanging.

	self deny: (supervisor stopResidentNamed: #hanging timeout: 200 milliSeconds).
	self assert: hanging isStopped.
	self deny: hanging hasRunningProcess
]

{ #category : #tests }
SoilResidentTest >> testStoppingOneResidentLeavesTheOthersRunning [
	"putting one resident aside must not close the database down around the others"
	| supervisor dummy active |
	self addResident: SoilTestResidentDescription new.
	self addResident: SoilTestActiveResidentDescription new.
	supervisor := self startedSupervisor.
	dummy := supervisor residentNamed: #dummy.
	active := supervisor residentNamed: #active.

	self assert: (supervisor stopResidentNamed: #dummy timeout: 5 seconds).
	self assert: dummy isStopped.
	self assert: active isStarted.
	self assert: active hasRunningProcess.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testStartingTwiceStartsNothingTwice [
	"a second start would give a resident that already has a process a second one"
	| supervisor resident txn |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.
	self assert: resident startCount equals: 1.

	txn := soil newTransaction.
	[ supervisor startAllIn: txn tickEvery: 1 hour reportEvery: 1 hour ] ensure: [ txn abort ].
	self assert: resident startCount equals: 1.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testStopAcknowledgedByCooperativeResident [
	"the receipt, and that it arrives without the process having to be terminated"
	| supervisor resident pending |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.

	pending := self stop: supervisor within: 5 seconds.
	self assert: pending isEmpty.
	self assert: resident isStopped
]

{ #category : #tests }
SoilResidentTest >> testStopTickKeepsEnsureFromRevivingIt [
	"otherwise the defensive restart would bring back the very tick the stop just
	cleared away"
	| supervisor |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	supervisor startTickEvery: 10 seconds reportEvery: 1 hour.
	self stop: supervisor within: 5 seconds.
	self deny: supervisor tickProcessIsRunning.

	supervisor ensureTickProcess.
	self deny: supervisor tickProcessIsRunning
]

{ #category : #tests }
SoilResidentTest >> testTickCountsProcessRestarts [
	"restarting silently looks exactly like being healthy from the outside, so the
	restart is counted"
	| supervisor resident |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.
	self assert: resident restartCount equals: 0.

	resident process terminate.
	supervisor tick.
	self assert: resident restartCount equals: 1.
	self assert: resident hasRunningProcess.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testTickErrorsAreIsolated [
	"a throwing resident must not abort the run for the others"
	| supervisor dummy |
	self addResident: SoilTestThrowingResidentDescription new.
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	dummy := supervisor residentNamed: #dummy.

	supervisor tick.
	self assert: dummy tickCount equals: 1.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testTickProcessFiresOnItsInterval [
	"the interval is the embedder's, the process is the supervisor's"
	| supervisor dummy |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	dummy := supervisor residentNamed: #dummy.
	supervisor startTickEvery: 20 milliSeconds reportEvery: 1 hour.

	self waitUntil: [ dummy tickCount >= 2 ] within: 5 seconds.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testTickRestartsATerminatedProcess [
	"only the resident knows whether its process should be running, so the tick
	is an extension point rather than a fixed checklist"
	| supervisor resident |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.
	resident process terminate.
	self deny: resident hasRunningProcess.

	supervisor tick.
	self assert: resident hasRunningProcess.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentTest >> testTwoPhaseStart [
	"every instance exists before any of them is started, so there is no start
	order to get right"
	| supervisor txn |
	self addResident: SoilTestResidentDescription new.
	self addResident: SoilTestPassiveResidentDescription new.

	supervisor := soil newResidentSupervisor.
	txn := soil newTransaction.
	[ supervisor loadFrom: txn.
	self assert: supervisor residents size equals: 2.
	self assert: (supervisor residents noneSatisfy: [ :each | each isStarted ]).
	supervisor startAllIn: txn tickEvery: 1 hour reportEvery: 1 hour.
	self assert: (supervisor residents allSatisfy: [ :each | each isStarted ]) ]
		ensure: [ txn abort ].
	self stop: supervisor within: 5 seconds
]

{ #category : #helpers }
SoilResidentTest >> waitUntil: aBlock within: aDuration [
	| deadline |
	deadline := DateAndTime now + aDuration.
	[ aBlock value or: [ DateAndTime now > deadline ] ]
		whileFalse: [ 10 milliSeconds wait ].
	self
		assert: aBlock value
		description: 'condition was not met within ', aDuration asString
]
