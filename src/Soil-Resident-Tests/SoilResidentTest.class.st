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
	supervisor startAllIn: txn ]
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
	supervisor startAllIn: txn.
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
