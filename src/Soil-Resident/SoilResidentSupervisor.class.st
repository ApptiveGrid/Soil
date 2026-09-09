"
I hold the live residents of one database, give named access to them, collect
their answers and distribute the tick. I am transient and exist exactly as long
as the database is open; my persisted counterpart is the
SoilResidentRegistry.

I do not evaluate. I gather answers and pass them on; whether a close, an error
or nothing at all follows is the embedder's decision. Accordingly I hold no
timeout and no interval of my own -- the stop timeout, the tick and the
reporting interval are all handed to me from outside.

My mutex protects my own dictionary against concurrent lookup, tick and
start/stop. It is deliberately not the mutex that closes the race between an
embedder's sweep and a resident starting work: that one belongs to whoever owns
the open databases, and a resident's work unit must not run inside a critical
block of mine.
"
Class {
	#name : #SoilResidentSupervisor,
	#superclass : #Object,
	#instVars : [
		'soil',
		'residents',
		'mutex',
		'tickProcess',
		'tickInterval',
		'tickRestartCount',
		'reportInterval',
		'nextReportAt',
		'emitsEveryStep'
	],
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentSupervisor class >> soilTransientInstVars [
	^ #( soil tickProcess )
]

{ #category : #adding }
SoilResidentSupervisor >> addResident: aResident [
	"refuses a name that is taken rather than replacing silently: the resident
	already here may be started and holding a process, and named access would
	then hand out the newcomer while the old one keeps running unreachable"
	aResident supervisor: self.
	mutex critical: [
		(residents includesKey: aResident name) ifTrue: [
			SoilResidentAlreadyPresent signalForName: aResident name ].
		residents
			at: aResident name
			put: aResident ]
]

{ #category : #running }
SoilResidentSupervisor >> ensureTickProcess [
	"defensive: bring the tick back if its process was terminated. A process
	cannot revive itself once it is gone, so somebody from outside has to look --
	the embedder calls this from a path it walks anyway, the way it already does
	for its own maintenance process.

	Does nothing until an interval has been set: without one there is no tick to
	keep alive.

	Reports, and counts: a tick that had to be brought back is the same kind of
	news as a resident's process restart, and a climbing number here is a crash
	loop rather than a one-off. The regular start does not come through here, so
	this line only ever means a revival."
	tickInterval ifNil: [ ^ self ].
	(tickProcess isNil or: [ tickProcess isTerminated ]) ifFalse: [ ^ self ].
	tickRestartCount := tickRestartCount + 1.
	self emit: 'residents: the tick process was gone, starting it again (',
		tickRestartCount printString, ')'.
	self startTickProcess
]

{ #category : #accessing }
SoilResidentSupervisor >> failedResidents [
	"for diagnosis, and for the embedder's decision whether a start failure keeps
	the database from opening"
	^ self residents select: [ :each | each hasFailed ]
]

{ #category : #stopping }
SoilResidentSupervisor >> flushAll [
	"after the receipts, so no resident writes while its loop is still running.
	Each opens and commits its own transaction; the embedder's stop transaction
	stays reading"
	self residents do: [ :each |
		[ each flushOnStop ]
			on: Error
			do: [ :err | each emit: 'failed to flush on stop: ', err messageText ] ]
]

{ #category : #hooks }
SoilResidentSupervisor >> fuelAccept: aGeneralMapper [
	^ aGeneralMapper visitSubstitution: self by: nil
]

{ #category : #testing }
SoilResidentSupervisor >> hasPendingWork [
	"disjunction over all residents: is there unprocessed work anywhere?"
	^ self residents anySatisfy: [ :each | self pendingWorkOf: each ]
]

{ #category : #testing }
SoilResidentSupervisor >> hasResidents [
	^ self residents notEmpty
]

{ #category : #private }
SoilResidentSupervisor >> idleStateOf: aResident [
	"a resident that throws on an answer must not drag the others along. An
	answer we could not get counts as non-idle: that keeps a database open, which
	is the harmless direction"
	^ [ aResident isIdle ]
		on: Error
		do: [ :err |
			aResident emit: 'failed to answer isIdle: ', err messageText.
			false ]
]

{ #category : #initialization }
SoilResidentSupervisor >> initialize [
	super initialize.
	residents := Dictionary new.
	mutex := Mutex new.
	tickRestartCount := 0.
	emitsEveryStep := true
]

{ #category : #testing }
SoilResidentSupervisor >> isIdle [
	"conjunction over all residents: is nobody working? A question -- the
	embedder decides what follows from it"
	^ self residents allSatisfy: [ :each | self idleStateOf: each ]
]

{ #category : #running }
SoilResidentSupervisor >> loadFrom: aTransaction [
	"phase one of the two-phase start: create every instance, start none. That
	resolves dependencies structurally -- no start order, no cycles, no declared
	dependencies.

	Refuses to run twice: a second load would build a second set of instances
	while the first set is started and holding processes."
	self hasResidents ifTrue: [ SoilResidentsAlreadyLoaded new signal ].
	(self registryIn: aTransaction) ifNotNil: [ :registry |
		registry descriptionsDo: [ :description |
			self addResident: (description newInstanceIn: aTransaction) ] ]
]

{ #category : #logging }
SoilResidentSupervisor >> durationString: aDuration [
	<ignoreNotImplementedSelectors: #( humanReadablePrintString )>
	"'30 minutes' rather than '0:00:30:00'. The whole worth of the line this goes
	into is that somebody can read it, so the interval should read like one.

	Version-tolerant for the same reason and in the same shape as
	SoilActiveResident>>wait:upTo: and SoilResidentReportingTest>>entriesOf::
	Soil builds on four Pharos and #humanReadablePrintString appears in none of
	the rest of this codebase, so it is asked for rather than assumed. The
	fallback is Duration's own printString, which is what the stop timeout has
	always used."
	^ (aDuration respondsTo: #humanReadablePrintString)
		ifTrue: [ aDuration humanReadablePrintString ]
		ifFalse: [ aDuration asString ]
]

{ #category : #logging }
SoilResidentSupervisor >> emit: aString [
	"through the database rather than emitting for myself: Soil>>emit: is the one
	seam an embedder fills, and a resident line has no reason to need a second one.

	Tolerates a missing database - a supervisor built without one is a unit test,
	and a test has no business being stopped by a log line."
	soil ifNotNil: [ :database | database emit: aString ]
]

{ #category : #accessing }
SoilResidentSupervisor >> emitsEveryStep [
	"whether the residents report every single work unit, and not only their state
	changes and what a tick summarises. On by default because a resident that says
	nothing between starting and stopping is exactly the silence this reporting
	exists to end - but it is the one level whose volume scales with the work, so
	an embedder under load can turn it down without touching code."
	^ emitsEveryStep
]

{ #category : #accessing }
SoilResidentSupervisor >> emitsEveryStep: aBoolean [
	emitsEveryStep := aBoolean
]

{ #category : #transactions }
SoilResidentSupervisor >> newTransaction [
	^ soil newTransaction
]

{ #category : #private }
SoilResidentSupervisor >> pendingWorkOf: aResident [
	"as with #idleStateOf:, an unavailable answer counts in the direction that
	keeps the database open"
	^ [ aResident hasPendingWork ]
		on: Error
		do: [ :err |
			aResident emit: 'failed to answer hasPendingWork: ', err messageText.
			true ]
]

{ #category : #accessing }
SoilResidentSupervisor >> registryIn: aTransaction [
	^ soil residentRegistryIn: aTransaction
]

{ #category : #accessing }
SoilResidentSupervisor >> residentNamed: aSymbol [
	^ self
		residentNamed: aSymbol
		ifAbsent: [ SoilResidentNotFound signalForName: aSymbol ]
]

{ #category : #accessing }
SoilResidentSupervisor >> residentNamed: aSymbol ifAbsent: aBlock [
	^ mutex critical: [ residents at: aSymbol ifAbsent: aBlock ]
]

{ #category : #accessing }
SoilResidentSupervisor >> residents [
	^ mutex critical: [ residents values asArray ]
]

{ #category : #accessing }
SoilResidentSupervisor >> soil [
	^ soil
]

{ #category : #accessing }
SoilResidentSupervisor >> soil: aSoil [
	soil := aSoil
]

{ #category : #running }
SoilResidentSupervisor >> startAllIn: aTransaction [
	"phase two: now each instance gets its start, with errors isolated per
	resident. A failure is left behind visibly as #failed plus the error, not
	merely logged -- the embedder needs the answer to decide. Reporting it is
	#markFailed:'s business, not mine: it is a state change like the others, and
	saying it here as well would say it twice"
	self residents do: [ :each |
		"only what has not been started: a second start would create a second
		process for a resident that already has one"
		each isCreated ifTrue: [
			[ each startIn: aTransaction.
			each markStarted ]
				on: Error
				do: [ :err | each markFailed: err ] ] ]
]

{ #category : #running }
SoilResidentSupervisor >> startTickEvery: aDuration reportEvery: aReportDuration [
	"both intervals are the embedder's business -- I only offer the tick. My own
	process, not a resident's: otherwise a hanging resident could not revive
	itself.

	I remember them so #ensureTickProcess can bring the process back without being
	told again.

	Deliberately one message and not two: a tick that can be started without a
	reporting interval is a tick that reports nothing, and nothing is exactly what
	could not be told apart from a tick that is not running. The one-argument form
	this replaces had no caller at all for weeks, which is how #ensureTickProcess
	came to be inert - the same mistake is not worth making twice.

	Says so, once, because the whole point of the periodic report is that somebody
	can see the mechanism is alive; a start that happened silently would leave the
	first report an unexplained half hour away."
	self stopTick.
	tickInterval := aDuration.
	reportInterval := aReportDuration.
	nextReportAt := DateAndTime now + aReportDuration.
	self startTickProcess.
	self emit: 'residents: ticking every ', (self durationString: aDuration),
		', reporting every ', (self durationString: aReportDuration),
		', for ', self residentNames
]

{ #category : #logging }
SoilResidentSupervisor >> reportIfDue [
	"the heartbeat: a line on a fixed schedule, whether or not anything happened.

	Every other line this mechanism emits hangs on an event, which means a
	database where nothing happens says nothing at all - and the silence of a
	living tick reads exactly like the silence of a dead one. That confusion is
	what this whole reporting effort was built to end, and leaving the periodic
	line to depend on work reproduced it one level up. So this is the one line
	allowed to say nothing new.

	Against a deadline rather than a count of ticks, so the interval means what it
	says even when the tick interval is changed underneath it."
	nextReportAt ifNil: [ ^ self ].
	DateAndTime now < nextReportAt ifTrue: [ ^ self ].
	nextReportAt := DateAndTime now + reportInterval.
	self emit: self reportLine
]

{ #category : #logging }
SoilResidentSupervisor >> reportLine [
	"one line for the whole database rather than one per resident: at this
	interval what somebody wants is a glance, and a glance is easier when the
	residents stand next to each other. Each of them says its own part - only a
	resident knows what it counts."
	^ String streamContents: [ :stream |
		stream nextPutAll: 'residents: '.
		self residents
			do: [ :each | stream nextPutAll: each statusLine ]
			separatedBy: [ stream nextPutAll: '; ' ] ]
]

{ #category : #accessing }
SoilResidentSupervisor >> reportInterval [
	"how far apart my periodic reports are, or nil while no tick is running. The
	embedder that handed the interval in is entitled to check that it arrived"
	^ reportInterval
]

{ #category : #accessing }
SoilResidentSupervisor >> residentNames [
	"for the lines that say who is involved without saying anything about them yet"
	^ String streamContents: [ :stream |
		self residents
			do: [ :each | stream nextPutAll: each name asString ]
			separatedBy: [ stream nextPutAll: ', ' ] ]
]

{ #category : #accessing }
SoilResidentSupervisor >> tickRestartCount [
	"how often my tick process had to be brought back. For diagnosis, and the same
	question SoilResident>>restartCount answers about a resident's own process"
	^ tickRestartCount
]

{ #category : #private }
SoilResidentSupervisor >> startTickProcess [
	tickProcess := [
		[ tickInterval wait.
		self tick ] repeat ]
		forkNamed: 'soil resident tick'
]

{ #category : #stopping }
SoilResidentSupervisor >> stopAllIn: aTransaction timeout: aDuration [
	"symmetric stop. Stopped in one phase, a resident still running could talk to
	one already stopped, so: ask everybody first, then wait for the receipts.

	After the timeout the process is terminated after all -- the deliberate hard
	way out, not the normal case: the image has to be able to quit, and a hanging
	resident must not prevent that. Bearable because the database is
	transactional; an uncommitted transaction leaves no half state behind.

	Answers the residents that did not acknowledge in time."
	| pending |
	self stopTick.
	self residents do: [ :each |
		[ each requestStop ]
			on: Error
			do: [ :err | each emit: 'failed on requestStop: ', err messageText ] ].
	pending := self waitForReceipts: aDuration.
	pending do: [ :each |
		each emit: 'did not acknowledge the stop within ', aDuration asString, ', terminating'.
		[ each terminateProcesses ]
			on: Error
			do: [ :err | each emit: 'failed to terminate: ', err messageText ] ].
	self flushAll.
	^ pending
]

{ #category : #running }
SoilResidentSupervisor >> stopTick [
	"forgets the interval as well: otherwise #ensureTickProcess would revive the
	very tick that the stop just cleared away"
	tickInterval := nil.
	nextReportAt := nil.
	tickProcess ifNotNil: [
		tickProcess terminate.
		tickProcess := nil ]
]

{ #category : #running }
SoilResidentSupervisor >> tick [
	"serially, one after the other, with errors isolated per resident: a throwing
	resident must not abort the run. No tick while stopping or stopped, otherwise
	the tick starts up again what the stop is just clearing away"
	self residents do: [ :each |
		(each isStopping or: [ each isStopped ]) ifFalse: [
			[ each tick ]
				on: Error
				do: [ :err | each emit: 'failed on tick: ', err messageText ] ] ].
	self reportIfDue
]

{ #category : #accessing }
SoilResidentSupervisor >> tickProcess [
	^ tickProcess
]

{ #category : #testing }
SoilResidentSupervisor >> tickProcessIsRunning [
	^ tickProcess notNil and: [ tickProcess isTerminated not ]
]

{ #category : #stopping }
SoilResidentSupervisor >> waitForReceipts: aDuration [
	"poll rather than wait out the whole timeout, so a quick stop returns
	quickly. Answers whoever is still missing"
	| deadline pending |
	deadline := DateAndTime now + aDuration.
	[ pending := self residents reject: [ :each | each isStopped ].
	pending isEmpty or: [ DateAndTime now > deadline ] ]
		whileFalse: [ 50 milliSeconds wait ].
	^ pending
]
