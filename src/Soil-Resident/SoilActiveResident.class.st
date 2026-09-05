"
A resident that drives its own work: I own a process, a work signal, and the loop
between them. The base runs only in other people's transactions and in the
supervisor's tick; I am the other half of the pair its #hasRunningProcess comment
names -- ""answered by the process-carrying residents; a passive one stays with
false"".

What is mine and what is not. Mine is everything the cooperative stop touches:
the process, the loop that checks the stop flag between two work units, the
receipt through #markStopped, the revival in #tick. *When* the next step is due
is not mine -- that is a run strategy, and it is a separate object because the
two vary independently. A resident's purpose says nothing about whether it runs
on a clock, on a signal, or on a signal followed by a collecting window; and the
same cadence serves residents that have nothing else in common.

The only thing a strategy may ask me is #hasPendingWork, and that is a flag,
never a question put to the database. Measured on the existing AGQueueTracker:
""is there more data"" is answered there as a side effect of doing the work,
inside the transaction that does it. Asking separately would cost a second
transaction per step and would be racy on top -- the answer can change between
the question and the step.

Hence the flag is cleared *before* a step, not after. Whoever signals a change
while I am in a step sets it again and is not lost; the worst case is one
redundant step, and that beats a lost one. A step that knowingly leaves work
behind says so by calling #noteWork.

A throwing step does not kill me. It is counted, the last one is kept, and the
loop goes on -- a transient failure must not take a resident down, and a
permanent one shows up as a climbing #stepErrorCount rather than as silence.
"
Class {
	#name : #SoilActiveResident,
	#superclass : #SoilResident,
	#instVars : [
		'process',
		'workSignal',
		'strategy',
		'pendingWork',
		'working',
		'lastStepError',
		'stepErrorCount'
	],
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilActiveResident class >> soilTransientInstVars [
	"nothing about me is persisted either; the list has to repeat the inherited
	entry, because a subclass declaration replaces its superclass's rather than
	adding to it"
	^ #( supervisor process workSignal strategy )
]

{ #category : #testing }
SoilActiveResident >> basicHasPendingWork [
	^ pendingWork
]

{ #category : #testing }
SoilActiveResident >> basicIsIdle [
	^ working not and: [ pendingWork not ]
]

{ #category : #running }
SoilActiveResident >> handleStepError: anError [
	"my step threw. Keep it and count it, then let the loop go on. Subclasses that
	can tell a transient failure from a fatal one may decide otherwise"
	lastStepError := anError.
	stepErrorCount := stepErrorCount + 1
]

{ #category : #testing }
SoilActiveResident >> hasRunningProcess [
	^ process notNil and: [ process isTerminated not ]
]

{ #category : #initialization }
SoilActiveResident >> initialize [
	super initialize.
	working := false.
	pendingWork := false.
	stepErrorCount := 0.
	workSignal := Semaphore new
]

{ #category : #testing }
SoilActiveResident >> isWorking [
	"inside a work unit. Distinguishes 'not idle because something is pending'
	from 'not idle because I am in it'"
	^ working
]

{ #category : #accessing }
SoilActiveResident >> lastStepError [
	"the last error a step threw, for diagnosis"
	^ lastStepError
]

{ #category : #'instance creation' }
SoilActiveResident >> newRunStrategy [
	^ self runStrategyClass new
		resident: self;
		yourself
]

{ #category : #notifying }
SoilActiveResident >> noteChanged [
	"a detached object of mine changed. For me that is work, not just a reason to
	wake: the flag has to be set as well, or the embedder's sweep could find me
	idle between the signal and my process being scheduled"
	self noteWork
]

{ #category : #notifying }
SoilActiveResident >> noteWork [
	"there is something to do. Set the flag first and signal second, both in the
	calling process -- the window between them is exactly what the sweep uses"
	pendingWork := true.
	workSignal signal
]

{ #category : #running }
SoilActiveResident >> prepareIn: aTransaction [
	"what a subclass does before its process exists, with the transaction the
	supervisor hands to all residents. Keep it small: anything that can fail on
	the environment belongs into the first work unit, because a throwing start
	keeps the whole database from opening.

	Default: nothing to prepare"
]

{ #category : #accessing }
SoilActiveResident >> process [
	^ process
]

{ #category : #accessing }
SoilActiveResident >> processName [
	^ 'soil resident ' , self name
]

{ #category : #running }
SoilActiveResident >> runLoop [
	"the stop flag is checked twice per turn on purpose: once before waiting, and
	once after, because #requestStop wakes me precisely while I wait"
	[ self shouldStop ] whileFalse: [
		self strategy awaitDue.
		self shouldStop ifFalse: [ self runStepProtected ] ].
	self markStopped
]

{ #category : #running }
SoilActiveResident >> runStep [
	"one work unit. One transaction at most, and none held across two units"
	self subclassResponsibility
]

{ #category : #running }
SoilActiveResident >> runStepProtected [
	"the flag is cleared before the step, so a change arriving during it survives.
	The signals that led here are spent in the same breath: a signal says that
	something happened, and what happened is about to be handled. Left standing,
	the next turn would find the flag down, wait on a signal that is already
	answered, and run an empty step -- which is exactly what a strategy that
	returns early on the flag would otherwise cause"
	working := true.
	pendingWork := false.
	workSignal consumeAllSignals.
	[ [ self runStep ]
		on: Error
		do: [ :anError | self handleStepError: anError ] ]
			ensure: [ working := false ]
]

{ #category : #accessing }
SoilActiveResident >> runStrategyClass [
	"which cadence drives me. Answered by every concrete active resident"
	^ self subclassResponsibility
]

{ #category : #running }
SoilActiveResident >> startIn: aTransaction [
	"phase two, once every resident exists. Subclasses hook into #prepareIn:
	rather than overriding me, so that preparing before forking is not a matter
	of remembering where the super send goes"
	self prepareIn: aTransaction.
	self startProcess
]

{ #category : #running }
SoilActiveResident >> startProcess [
	process := [ self runLoop ] forkNamed: self processName
]

{ #category : #accessing }
SoilActiveResident >> stepErrorCount [
	"how many steps of mine threw. A crash loop is a climbing number here"
	^ stepErrorCount
]

{ #category : #accessing }
SoilActiveResident >> strategy [
	^ strategy ifNil: [ strategy := self newRunStrategy ]
]

{ #category : #accessing }
SoilActiveResident >> strategy: aRunStrategy [
	strategy := aRunStrategy.
	aRunStrategy resident: self
]

{ #category : #stopping }
SoilActiveResident >> terminateProcesses [
	"the hard way out, after my receipt failed to arrive within the timeout"
	process ifNotNil: [ :p | p terminate ].
	self markStopped
]

{ #category : #running }
SoilActiveResident >> tick [
	"a terminated process would leave my work undone forever. Bring it back, and
	count it, so that a crash loop is visible instead of looking like health"
	self hasRunningProcess ifFalse: [
		self noteProcessRestart.
		self startProcess ]
]

{ #category : #waiting }
SoilActiveResident >> waitForWork [
	"what a strategy uses to block until something happens. All signals are
	consumed, so n signals do not become n runs -- the flag says whether there is
	work, the signal only says that something happened"
	workSignal wait.
	workSignal consumeAllSignals
]

{ #category : #waiting }
SoilActiveResident >> waitForWorkUpTo: aDuration [
	"the same, bounded. Returns early when woken -- by new work or by a stop"
	workSignal waitTimeoutMilliseconds: aDuration asMilliSeconds.
	workSignal consumeAllSignals
]

{ #category : #stopping }
SoilActiveResident >> wakeUp [
	"my loop blocks in the strategy and would never get to see the stop flag"
	workSignal signal
]
