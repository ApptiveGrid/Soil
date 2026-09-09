"
What a resident says while it runs, and what it stays quiet about.

The subject is not that a line reaches a log - that is Soil>>emit: and is asked
about separately here in one test. The subject is which moments produce a line
at all, because until now only failures did, and silence therefore meant either
'all is well' or 'nothing is running' with no way to tell the two apart.

The test database collects what is reported instead of signalling it, so these
tests read the lines directly and depend on no logger.
"
Class {
	#name : #SoilResidentReportingTest,
	#superclass : #TestCase,
	#instVars : [
		'soil',
		'supervisor'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #helpers }
SoilResidentReportingTest >> entriesOf: aMemoryLogger [
	<ignoreNotImplementedSelectors: #( entries recordings )>
	"The pragma is not a way around the lint rule, it is the answer to it: one of
	the two selectors below is missing in whichever Pharo is running, and which one
	that is, is the whole point of this method - the same shape, and for the same
	reason, as SoilActiveResident>>wait:upTo:.

	What a MemoryLogger calls its collected signals differs across the Pharo
	versions Soil builds on: #entries does not exist before Pharo 13, and
	#recordings is deprecated from Pharo 13 on. Asking #entries first therefore
	never reaches the deprecated one where it is deprecated - which matters more
	here than tidiness, because that deprecation carries a transformWith: rule and
	rewrites the source of whichever method called it.

	Fails loudly rather than answering something if neither is there."
	(aMemoryLogger respondsTo: #entries) ifTrue: [ ^ aMemoryLogger entries ].
	(aMemoryLogger respondsTo: #recordings) ifTrue: [ ^ aMemoryLogger recordings ].
	self error: 'no known way to read a MemoryLogger in this Pharo'
]

{ #category : #helpers }
SoilResidentReportingTest >> path [
	^ 'soil-resident-reporting-tests'
]

{ #category : #helpers }
SoilResidentReportingTest >> residentWith: aBlock [
	| description txn |
	description := SoilTestActiveResidentDescription new.
	aBlock value: description.
	soil addResidentDescription: description.
	txn := soil newTransaction.
	[ supervisor loadFrom: txn.
	supervisor startAllIn: txn ]
		ensure: [ txn abort ].
	^ supervisor residentNamed: #active
]

{ #category : #running }
SoilResidentReportingTest >> setUp [
	super setUp.
	soil := SoilTestResidentDatabase path: self path.
	soil
		destroy;
		initializeFilesystem;
		initializeRoot.
	supervisor := soil newResidentSupervisor
]

{ #category : #helpers }
SoilResidentReportingTest >> startAll [
	"every description has to be registered before this: #loadFrom: refuses a
	second load, deliberately, so residents come up in one go and not one by one"
	| txn |
	txn := soil newTransaction.
	[ supervisor loadFrom: txn.
	supervisor startAllIn: txn ]
		ensure: [ txn abort ]
]

{ #category : #helpers }
SoilResidentReportingTest >> stopWithin: aDuration [
	| txn |
	txn := soil newTransaction.
	^ [ supervisor stopAllIn: txn timeout: aDuration ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ]
]

{ #category : #running }
SoilResidentReportingTest >> tearDown [
	supervisor ifNotNil: [ self stopWithin: 2 seconds ].
	soil ifNotNil: [
		soil close.
		soil destroy ].
	super tearDown
]

{ #category : #tests }
SoilResidentReportingTest >> testARevivedTickSaysSoAndCounts [
	"a tick that had to be brought back is the same news as a resident's process
	restart, and a climbing number is a crash loop rather than a one-off"
	| resident |
	resident := self residentWith: [ :d | d ].
	supervisor startTickEvery: 1 hour reportEvery: 1 hour.
	supervisor tickProcess terminate.
	supervisor ensureTickProcess.

	self assert: supervisor tickRestartCount equals: 1.
	self assert: (soil reportedMatching: 'the tick process was gone') size equals: 1.
	self assert: (soil reportedMatching: 'starting it again (1)') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testAnActiveResidentAddsItsStepsAndErrorsToTheReport [
	"the base says who and how, the subclass adds what only it counts"
	| resident |
	resident := self residentWith: [ :d | d ].
	resident noteWork.
	self assert: (resident waitForStepWithin: 2 seconds).

	self assert: resident statusLine equals: 'active started, 1 step, 0 errors'
]

{ #category : #tests }
SoilResidentReportingTest >> testNothingIsReportedBeforeTheIntervalHasPassed [
	"otherwise the interval would not be one"
	self residentWith: [ :d | d ].
	supervisor startTickEvery: 1 hour reportEvery: 1 hour.
	supervisor tick.

	self assert: (soil reportedMatching: 'steps, 0 errors') size equals: 0
]

{ #category : #tests }
SoilResidentReportingTest >> testStartingTheTickSaysSo [
	"the first report is a whole interval away, so a silent start would leave that
	interval indistinguishable from a tick that never came up"
	self residentWith: [ :d | d ].
	supervisor startTickEvery: 30 seconds reportEvery: 30 minutes.

	self assert: (soil reportedMatching: 'ticking every') size equals: 1.
	self assert: (soil reportedMatching: 'reporting every') size equals: 1.
	"and it says who it ticks for, because a tick with no residents is the case
	worth noticing"
	self assert: (soil reportedMatching: 'for active') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testTheReportComesEvenWhenNothingHappened [
	"the point of the whole heartbeat: every other line here hangs on an event, so
	a quiet database said nothing at all - and a living tick was not to be told
	apart from a dead one"
	| resident |
	resident := self residentWith: [ :d | d ].
	supervisor startTickEvery: 1 hour reportEvery: 20 milliSeconds.
	self assert: resident stepCount equals: 0.
	50 milliSeconds wait.
	supervisor tick.

	self assert: (soil reportedMatching: 'active started, 0 steps, 0 errors') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testTheReportNamesEveryResidentInOneLine [
	"one line for the database rather than one per resident: at this interval what
	somebody wants is a glance"
	soil addResidentDescription: SoilTestActiveResidentDescription new.
	soil addResidentDescription: SoilTestResidentDescription new.
	self startAll.
	supervisor startTickEvery: 1 hour reportEvery: 20 milliSeconds.
	50 milliSeconds wait.
	supervisor tick.

	self assert: (soil reportedMatching: 'active started') size equals: 1.
	self assert: (soil reportedMatching: 'dummy started') size equals: 1.
	self assert: ((soil reportedMatching: 'dummy started') first
		includesSubstring: 'active started')
]

{ #category : #tests }
SoilResidentReportingTest >> testAFailedStartIsReportedOnce [
	"the supervisor used to say it as well as the state machine, which said it
	twice in two different shapes"
	| description txn |
	description := SoilTestFailingResidentDescription new.
	soil addResidentDescription: description.
	txn := soil newTransaction.
	[ supervisor loadFrom: txn.
	supervisor startAllIn: txn ]
		ensure: [ txn abort ].
	self assert: (soil reportedMatching: 'failed to start') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testAStepFailureIsReportedEvenWhenStepsAreNot [
	"a failure is not routine volume: turning the steps down must not turn the
	failures off with them"
	| resident |
	supervisor emitsEveryStep: false.
	resident := self residentWith: [ :d | d ].
	resident throwOnStep: true.
	resident noteWork.
	self assert: (resident waitForStepWithin: 2 seconds).
	"the routine line is gone, and the failure - which names the step it was, so
	the number is not lost with the routine line - is not"
	self deny: (soil reported includes: 'resident active: step 1').
	self assert: (soil reportedMatching: 'step 1 failed: the step was told to throw') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testATickReportsWorkDoneSinceTheLastOne [
	| resident |
	resident := self residentWith: [ :d | d ].
	resident noteWork.
	self assert: (resident waitForStepWithin: 2 seconds).
	resident tick.
	self assert: (soil reportedMatching: '1 step since the last report') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testATickWithoutWorkSaysNothing [
	"otherwise a quiet resident would fill the log at the tick's cadence, and the
	lines that mean something would drown in the ones that do not"
	| resident |
	resident := self residentWith: [ :d | d ].
	resident tick.
	resident tick.
	self assert: (soil reportedMatching: 'since the last report') isEmpty
]

{ #category : #tests }
SoilResidentReportingTest >> testEveryLineNamesItsResident [
	"several residents report into one database, so a line that does not say whose
	it is cannot be read.

	The database reports about itself as well - a segment created, an open, a close -
	so what is asked here is that a resident's lines name it, not that every line the
	database collected does. Hence the clearing: from there on only the resident acts."
	| resident |
	resident := self residentWith: [ :d | d ].
	soil reported removeAll.
	resident noteWork.
	self assert: (resident waitForStepWithin: 2 seconds).
	self deny: soil reported isEmpty.
	self assert: (soil reported allSatisfy: [ :each | each beginsWith: 'resident active: ' ])
]

{ #category : #tests }
SoilResidentReportingTest >> testStartingAndStoppingAreReported [
	"the whole point: silence now means nothing is running, because a resident that
	is running has said so"
	self residentWith: [ :d | d ].
	self assert: (soil reportedMatching: 'started') size equals: 1.
	self stopWithin: 2 seconds.
	supervisor := nil.
	self assert: (soil reportedMatching: 'stopping') size equals: 1.
	self assert: (soil reportedMatching: 'stopped') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testStoppingTwiceIsReportedOnce [
	"an embedder that stops explicitly and then closes stops twice, and the second
	one is not a state change - saying it again would describe a transition that
	did not happen"
	self residentWith: [ :d | d ].
	self stopWithin: 2 seconds.
	self stopWithin: 2 seconds.
	supervisor := nil.
	self assert: (soil reportedMatching: 'stopping') size equals: 1.
	self assert: (soil reportedMatching: 'stopped') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testStepsAreReportedWhenAskedFor [
	| resident |
	resident := self residentWith: [ :d | d ].
	resident noteWork.
	self assert: (resident waitForStepWithin: 2 seconds).
	self assert: (soil reportedMatching: 'step 1') size equals: 1
]

{ #category : #tests }
SoilResidentReportingTest >> testStepsAreSilentWhenTurnedDown [
	"the one level whose volume scales with the work"
	| resident |
	supervisor emitsEveryStep: false.
	resident := self residentWith: [ :d | d ].
	resident noteWork.
	self assert: (resident waitForStepWithin: 2 seconds).
	self assert: (soil reportedMatching: 'step ') isEmpty
]

{ #category : #tests }
SoilResidentReportingTest >> testTheDefaultSeamEmitsASoilSignalNamingTheDatabase [
	"what a database that does not override Soil>>emit: does - the only test here
	that goes through Beacon, because it is the only one about the default"
	| logger plain collected |
	plain := Soil path: self path , '-default'.
	plain destroy; initializeFilesystem.
	logger := MemoryLogger new.
	[ logger runFor: SoilSignal during: [ plain emit: 'something happened' ] ]
		ensure: [ plain close. plain destroy ].
	"read through #entriesOf:, because what a logger calls its collected signals
	differs across the Pharo versions Soil builds on"
	collected := self entriesOf: logger.
	self assert: collected size equals: 1.
	self assert: collected first class equals: SoilSignal.
	self assert: collected first databaseName equals: plain name
]
