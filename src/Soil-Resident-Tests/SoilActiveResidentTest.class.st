"
What the active half of a resident has to be provable against: it starts a
process, works when there is work, drains while there is more, survives a
throwing step, is revived by the tick, and acknowledges a cooperative stop
without sitting out its own cadence first.

The tests synchronise on the work itself -- the dummy signals a semaphore at the
end of every step -- rather than on a sleep chosen long enough to be safe. The
durations that do appear are upper bounds for waiting, not pauses.
"
Class {
	#name : #SoilActiveResidentTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'supervisor'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #helpers }
SoilActiveResidentTest >> path [
	^ 'soil-active-resident-tests'
]

{ #category : #helpers }
SoilActiveResidentTest >> residentWith: aBlock [
	"add a dummy active resident configured by the block, start everything the way
	an embedder does, and answer the running instance"
	| description txn |
	description := SoilTestActiveResidentDescription new.
	aBlock value: description.
	soil addResidentDescription: description.
	supervisor := soil newResidentSupervisor.
	txn := soil newTransaction.
	[ supervisor loadFrom: txn.
	supervisor startAllIn: txn ]
		ensure: [ txn abort ].
	^ supervisor residentNamed: #active
]

{ #category : #running }
SoilActiveResidentTest >> setUp [
	super setUp.
	soil := SoilTestResidentDatabase path: self path.
	soil
		destroy;
		initializeFilesystem;
		initializeRoot
]

{ #category : #helpers }
SoilActiveResidentTest >> stopWithin: aDuration [
	| txn |
	txn := soil newTransaction.
	^ [ supervisor stopAllIn: txn timeout: aDuration ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ]
]

{ #category : #running }
SoilActiveResidentTest >> tearDown [
	supervisor ifNotNil: [ self stopWithin: 2 seconds ].
	soil ifNotNil: [
		soil close.
		soil destroy ].
	super tearDown
]

{ #category : #tests }
SoilActiveResidentTest >> testACoalescingWindowTurnsABurstIntoOneStep [
	"the reason the strategy exists: work that is triggered far more often than it
	needs to be done must not cost one step per trigger"
	| resident |
	resident := self residentWith: [ :d |
		d cadence: #coalescing; window: 200 milliSeconds ].

	5 timesRepeat: [ resident noteWork ].

	self assert: (resident waitForStepWithin: 3 seconds).
	self assert: resident stepCount equals: 1.
	self deny: (resident waitForStepWithin: 300 milliSeconds)
]

{ #category : #tests }
SoilActiveResidentTest >> testAThrowingStepIsCountedAndTheLoopSurvivesIt [
	"a transient failure must not take a resident down; a permanent one shows up
	as a climbing count rather than as silence"
	| resident |
	resident := self residentWith: [ :d | d cadence: #signal ].
	resident throwOnStep: true.

	resident noteWork.
	self assert: (resident waitForStepWithin: 3 seconds).

	self assert: resident stepErrorCount equals: 1.
	self assert: resident lastStepError notNil.
	self assert: resident hasRunningProcess.

	resident throwOnStep: false.
	resident noteWork.
	self assert: (resident waitForStepWithin: 3 seconds).
	self assert: resident stepCount equals: 2.
	self assert: resident stepErrorCount equals: 1
]

{ #category : #tests }
SoilActiveResidentTest >> testAnIntervalIsDueAtOnceAndNotAgainBeforeItElapsed [
	"unit test on the strategy, without a process: a freshly opened database
	should not stay stale for a first interval, and afterwards the clock decides"
	| strategy |
	strategy := SoilIntervalRunStrategy new
		resident: SoilTestActiveResident new;
		interval: 10 minutes;
		yourself.

	self assert: strategy isDue.

	strategy lastRun: DateAndTime now.
	self deny: strategy isDue.

	strategy lastRun: DateAndTime now - 11 minutes.
	self assert: strategy isDue
]

{ #category : #tests }
SoilActiveResidentTest >> testAnIntervalWaitIsCutShortByAStopRequest [
	"the failure the old AGIntervalRunStrategy has: waited out on the clock, a
	stop would have to sit through the whole interval, and the embedder's timeout
	would have to exceed the longest interval in the system"
	| resident pending |
	resident := self residentWith: [ :d |
		d cadence: #interval; interval: 10 minutes ].
	self assert: (resident waitForStepWithin: 3 seconds).

	pending := self stopWithin: 2 seconds.
	supervisor := nil.

	self assert: pending isEmpty.
	self assert: resident isStopped
]

{ #category : #tests }
SoilActiveResidentTest >> testDrainsWhileWorkRemainsWithoutFurtherSignals [
	"one wake-up, four steps: a tracker woken once works through what is there
	instead of needing a signal per item"
	| resident |
	resident := self residentWith: [ :d | d cadence: #signal ].
	resident workToLeave: 3.

	resident noteWork.

	1 to: 4 do: [ :each |
		self
			assert: (resident waitForStepWithin: 3 seconds)
			description: 'step ' , each printString , ' did not arrive' ].
	self assert: resident stepCount equals: 4.
	self deny: (resident waitForStepWithin: 300 milliSeconds)
]

{ #category : #tests }
SoilActiveResidentTest >> testStartsAProcessAndAcknowledgesACooperativeStop [
	| resident pending |
	resident := self residentWith: [ :d | d cadence: #signal ].

	self assert: resident hasRunningProcess.
	self assert: resident isStarted.
	self assert: resident prepareCount equals: 1.

	pending := self stopWithin: 2 seconds.
	supervisor := nil.

	self assert: pending isEmpty.
	self assert: resident isStopped
]

{ #category : #tests }
SoilActiveResidentTest >> testThePendingFlagIsClearedBeforeTheStepNotAfter [
	"so that a change arriving while a step runs survives it. Cleared afterwards,
	it would be swallowed; cleared before, the worst case is one redundant step,
	and that beats a lost one"
	| resident |
	resident := SoilTestActiveResident new.

	resident noteWork.
	resident workToLeave: 0.
	resident runStepProtected.
	self deny: resident hasPendingWork.

	resident workToLeave: 1.
	resident runStepProtected.
	self assert: resident hasPendingWork
]

{ #category : #tests }
SoilActiveResidentTest >> testTickRevivesATerminatedProcessAndCountsTheRestart [
	"a dead process would leave the work undone forever, and restarting silently
	looks exactly like health from the outside"
	| resident |
	resident := self residentWith: [ :d | d cadence: #signal ].
	resident process terminate.
	self deny: resident hasRunningProcess.

	supervisor tick.

	self assert: resident hasRunningProcess.
	self assert: resident restartCount equals: 1
]

{ #category : #tests }
SoilActiveResidentTest >> testWorkFromOutsideRunsAStep [
	| resident |
	resident := self residentWith: [ :d | d cadence: #signal ].
	self assert: resident stepCount equals: 0.

	resident noteWork.

	self assert: (resident waitForStepWithin: 3 seconds).
	self assert: resident stepCount equals: 1
]
