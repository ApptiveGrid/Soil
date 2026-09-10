"
I am the live half of a resident: I exist exactly as long as the database is
open, and I carry the runtime state of one concrete resident.

Subclasses add their own runtime state -- semaphores, counters, in-flight sets,
processes. Processes belong to the subclass, not to me: a passive resident has
none, a queue has a dispatcher plus several workers, so a single #process field
here would fit neither.

I hold no materialized Soil objects, only #descriptionId. I outlive many
transactions; a held object would be a snapshot that grows staler with every
foreign change and, on writing, either conflicts or overwrites silently.

My state machine:

	created --startIn:--> started --requestStop--> stopping --> stopped
	   |
	   +--startIn: throws--> failed

The transitions are driven by the supervisor, which isolates errors per resident;
I keep the state and answer the questions about it. What I answer are questions
-- #isIdle and #hasPendingWork are read by the embedder, and I never decide
whether the database closes.
"
Class {
	#name : #SoilResident,
	#superclass : #Object,
	#instVars : [
		'descriptionId',
		'supervisor',
		'state',
		'stopRequested',
		'error',
		'restartCount'
	],
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResident class >> soilTransientInstVars [
	"nothing about me is persisted, but declaring it keeps a resident that ends up
	in a written graph by accident from dragging the supervisor along"
	^ #( supervisor )
]

{ #category : #testing }
SoilResident >> basicHasPendingWork [
	"what subclasses answer. Default: no work"
	^ false
]

{ #category : #testing }
SoilResident >> basicIsIdle [
	"what subclasses answer. Default: not working"
	^ true
]

{ #category : #accessing }
SoilResident >> descriptionId [
	^ descriptionId
]

{ #category : #accessing }
SoilResident >> descriptionId: aSoilObjectId [
	descriptionId := aSoilObjectId
]

{ #category : #accessing }
SoilResident >> descriptionIn: aTransaction [
	"my description, resolved in the transaction that is running now"
	^ aTransaction objectWithId: descriptionId
]

{ #category : #logging }
SoilResident >> count: anInteger of: aNoun [
	"so that a report says '1 step' and not '1 steps'. A line written to be read by
	somebody should read like a line"
	^ anInteger printString, ' ', (anInteger = 1 ifTrue: [ aNoun ] ifFalse: [ aNoun, 's' ])
]

{ #category : #logging }
SoilResident >> statusLine [
	"what I contribute to the supervisor's periodic report: who I am and how I am,
	in the fewest words that still tell a healthy resident from a stuck one.

	Deliberately not sent through #emit:, because this is not a line of its own -
	the supervisor joins what all residents say into one. Subclasses add what only
	they count, and call me first, so that the state stays at the front of every
	entry no matter who wrote the rest."
	| line |
	line := self name asString, ' ', state.
	restartCount > 0 ifTrue: [
		line := line, ', ', (self count: restartCount of: 'restart') ].
	self hasFailed ifTrue: [
		line := line, ' (', (error ifNil: [ 'no error recorded' ] ifNotNil: [ :e | e messageText ifNil: [ e class name ] ]), ')' ].
	^ line
]

{ #category : #logging }
SoilResident >> emit: aString [
	"every line of mine names me, so that lines from several residents in one
	database can be told apart and a stable prefix can be searched for. That the
	prefix is decided here once, rather than written out at each of the places
	that report, is the point of this method - it does not save typing, it keeps
	the lines the same shape.

	Reports through the supervisor, which reports through the database. A resident
	without a supervisor is one that was never added to one, which happens in unit
	tests, and a test has no business being stopped by a log line."
	supervisor ifNotNil: [ :s | s emit: 'resident ', self name asString, ': ', aString ]
]

{ #category : #accessing }
SoilResident >> error [
	"the start error, if I am #failed"
	^ error
]

{ #category : #stopping }
SoilResident >> flushOnStop [
	"my last chance to write. The only case in which a resident does work while
	stopping: state collected in memory and not yet persisted has to go out
	instead of being discarded.

	I open my own transaction for it and commit it myself -- the embedder's stop
	transaction stays reading and is discarded. That way a failed flush of mine
	does not touch the other residents, and a stop with nothing pending causes no
	write at all.

	Default: nothing to do."
]

{ #category : #testing }
SoilResident >> hasFailed [
	^ state = #failed
]

{ #category : #testing }
SoilResident >> hasPendingWork [
	"is there unprocessed work? A question, not a decision -- the embedder reads
	it, I never decide whether the database closes.

	A #failed resident answers no here rather than leaving it to the subclass,
	so it cannot block a decision it can no longer influence.

	Whoever signals new work has to set the underlying flag synchronously, in the
	signalling process -- not first in the woken resident process. Between signal
	and scheduling is exactly the window in which the embedder's sweep strikes."
	^ self hasFailed not and: [ self basicHasPendingWork ]
]

{ #category : #testing }
SoilResident >> hasRunningProcess [
	"do I own a process that has to leave its loop before I count as stopped?
	Answered by the process-carrying residents; a passive one stays with false"
	^ false
]

{ #category : #initialization }
SoilResident >> initialize [
	super initialize.
	state := #created.
	stopRequested := false.
	restartCount := 0
]

{ #category : #testing }
SoilResident >> isCreated [
	"I exist but my #startIn: has not run -- between phase one and phase two"
	^ state = #created
]

{ #category : #testing }
SoilResident >> isIdle [
	"am I working right now? A question, not a decision -- and it answers 'is
	there unprocessed work', not 'is my semaphore above zero': semaphores count
	signals up, and you get n idle runs after n signals. A dirty flag beats the
	signal counter.

	A #failed resident answers idle for the same reason it answers no pending
	work, and here too rather than in the subclass."
	^ self hasFailed or: [ self basicIsIdle ]
]

{ #category : #testing }
SoilResident >> isStarted [
	^ state = #started
]

{ #category : #testing }
SoilResident >> isStopped [
	"the receipt the embedder waits for. Only now may it release me"
	^ state = #stopped
]

{ #category : #testing }
SoilResident >> isStopping [
	^ state = #stopping
]

{ #category : #accessing }
SoilResident >> markFailed: anError [
	"my #startIn: has thrown. I am not usable; whether that keeps the database
	from opening is the embedder's decision"
	state := #failed.
	error := anError.
	self emit: 'failed to start: ', anError messageText
]

{ #category : #accessing }
SoilResident >> markStarted [
	state := #started.
	self emit: 'started'
]

{ #category : #accessing }
SoilResident >> markStopped [
	"called by my own process when it has left its loop between two work units.

	Reports only a transition that happened: #terminateProcesses marks a resident
	stopped as well, and it may run after the loop already did"
	state = #stopped ifTrue: [ ^ self ].
	state := #stopped.
	self emit: 'stopped'
]

{ #category : #accessing }
SoilResident >> name [
	self subclassResponsibility
]

{ #category : #transactions }
SoilResident >> newTransaction [
	^ supervisor newTransaction
]

{ #category : #notifying }
SoilResident >> noteChanged [
	"a detached object of mine reports that something about it changed. Default:
	treat it as work to do and wake up. Overridden by residents that need to tell
	'there is new work' apart from the wake-up that #requestStop sends."
	self wakeUp
]

{ #category : #accessing }
SoilResident >> noteProcessRestart [
	"a resident that revives its own process in #tick counts the restart here, so
	a crash loop becomes visible instead of masquerading as health -- restarting
	silently looks exactly like being healthy from the outside.

	Deliberately only counted, with no upper bound: what number should turn a
	resident into #failed is decided once a real active resident has produced
	real numbers. Counted and said: a number nobody reads is not visibility, and
	a restart is rare enough that saying it costs nothing."
	restartCount := restartCount + 1.
	self emit: 'process restarted (', restartCount printString, ')'
]

{ #category : #running }
SoilResident >> restartIn: aTransaction [
	"start again, reading my configuration off my description the way a first start
	does -- #startIn: is 'read the config, then run', and there is no second place
	that pair lives.

	Whoever changed my description calls this. The base deliberately does not watch
	for such a change: what follows from one differs per field -- an interval is a
	setter, a changed host invalidates the progress kept in my workspace -- so the
	decision belongs to the embedder that made the change, not to a version marker
	here (Norbert, 2026-09-10).

	Clears the stop flag first. It survives a stop, and a loop started with it still
	up leaves at its very first check and marks itself stopped again: a restart that
	reports success and started nothing.

	Also the way back for a resident that is #failed, whether its first start threw
	or a later guard put it there. A #startIn: that throws again lands in
	#markFailed: exactly as it does in phase two."
	stopRequested := false.
	[ self startIn: aTransaction.
	self markStarted ]
		on: Error
		do: [ :err | self markFailed: err ]
]

{ #category : #stopping }
SoilResident >> requestStop [
	"cooperative, never Process>>suspend: that mid-transaction leaves half writes
	and held locks behind. I only set the flag -- a resident with a process checks
	it between two work units and answers #isStopped once it has left the loop.
	Without a process there is nobody who would notice the flag, so I am stopped
	right away.

	Asking a resident that has already stopped to stop does nothing at all. It used
	to put it back into #stopping and out again, which is a state cycle that never
	happened - and said so twice in the log. Two stops in a row is not exotic: an
	embedder that stops explicitly and then closes does exactly that."
	self isStopped ifTrue: [ ^ self ].
	stopRequested := true.
	state := #stopping.
	self emit: 'stopping'.
	self wakeUp.
	self hasRunningProcess ifFalse: [ self markStopped ]
]

{ #category : #accessing }
SoilResident >> residentNamed: aSymbol [
	^ supervisor residentNamed: aSymbol
]

{ #category : #accessing }
SoilResident >> restartCount [
	"how often my process had to be revived. For diagnosis"
	^ restartCount
]

{ #category : #testing }
SoilResident >> shouldStop [
	"what my run loop checks between two work units"
	^ stopRequested
]

{ #category : #running }
SoilResident >> startIn: aTransaction [
	"called once, after every instance exists (two-phase start), with the
	transaction the supervisor hands to all of us.

	Do very little here -- read the description, create a process. Everything
	that can fail on the environment belongs into the first work unit instead,
	because with fail-early embedding a throwing #startIn: keeps the whole
	database from opening, and a transient outage would then knock over healthy
	databases reproducibly.

	Whether I have work must be settled by the time this returns, synchronously.
	Deciding it only when my process first gets scheduled leaves the sweep a
	window."
]

{ #category : #accessing }
SoilResident >> supervisor [
	"kept for late binding: I ask for other residents at use time via
	#residentNamed:, I do not resolve them into instance variables at start.
	Otherwise the ordering problem is only moved from the start to the stop --
	I hold B, B gets stopped, I keep calling it"
	^ supervisor
]

{ #category : #accessing }
SoilResident >> supervisor: aResidentSupervisor [
	supervisor := aResidentSupervisor
]

{ #category : #stopping }
SoilResident >> terminateProcesses [
	"the hard way out, used by the supervisor only after my receipt failed to
	arrive within the timeout. Whoever owns processes terminates them here and
	marks himself stopped; a passive resident has nothing to do"
	self markStopped
]

{ #category : #running }
SoilResident >> tick [
	"periodic nudge from the supervisor. What happens is up to me: pull my process
	up again if it has terminated, clean up, compute statistics, kick off follow-up
	work. It is an extension point, not a fixed checklist -- only I know whether
	my process should be running.

	I do not do the work here: the tick runs serially for all residents, so an
	expensive step of mine would block everyone else's. And there is no
	transaction from the caller -- if I write, one tick is one transaction of
	my own.

	Default: nothing to do."
]

{ #category : #stopping }
SoilResident >> wakeUp [
	"called by #requestStop before the receipt is awaited. A resident whose
	process is blocked on a wake signal would otherwise never get to check the
	flag, and the cooperative stop would run into its timeout every time.
	Whoever waits on a semaphore signals it here.

	Default: nothing to do."
]
{ #category : #transactions }
SoilResident >> withTransactionDo: aBlock [
	"one work unit is one transaction, and never one held open across my
	process's lifetime. The block commits when it wrote something; otherwise the
	ensure discards it. A commit leaves the transaction aborted already, so the
	ensure does not touch it"
	| txn |
	txn := self newTransaction.
	^ [ aBlock cull: txn ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ]
]

{ #category : #accessing }
SoilResident >> workspaceIn: aTransaction [
	^ (self descriptionIn: aTransaction) workspace
]

