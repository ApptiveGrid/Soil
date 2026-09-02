"
I hold the live residents of one database, give named access to them, collect
their answers and distribute the tick. I am transient and exist exactly as long
as the database is open; my persisted counterpart is the
SoilResidentRegistry.

I do not evaluate. I gather answers and pass them on; whether a close, an error
or nothing at all follows is the embedder's decision. Accordingly I know no
timeout and no interval of my own -- both are handed to me from outside.

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
		'tickProcess'
	],
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentSupervisor class >> soilTransientInstVars [
	^ #( soil tickProcess )
]

{ #category : #adding }
SoilResidentSupervisor >> addResident: aResident [
	aResident supervisor: self.
	mutex critical: [
		residents
			at: aResident name
			put: aResident ]
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
			do: [ :err | self log: 'resident ', each name asString, ' failed to flush on stop: ', err messageText ] ]
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

{ #category : #private }
SoilResidentSupervisor >> idleStateOf: aResident [
	"a resident that throws on an answer must not drag the others along. An
	answer we could not get counts as non-idle: that keeps a database open, which
	is the harmless direction"
	^ [ aResident isIdle ]
		on: Error
		do: [ :err |
			self log: 'resident ', aResident name asString, ' failed to answer isIdle: ', err messageText.
			false ]
]

{ #category : #initialization }
SoilResidentSupervisor >> initialize [
	super initialize.
	residents := Dictionary new.
	mutex := Mutex new
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
	dependencies"
	(self registryIn: aTransaction) ifNotNil: [ :registry |
		registry descriptionsDo: [ :description |
			self addResident: (description newInstanceIn: aTransaction) ] ]
]

{ #category : #logging }
SoilResidentSupervisor >> log: aString [
	"overridable: an embedder that has its own logging fills this. Soil's default
	emits a signal, the same way SoilApplicationMigration does"
	SoilSignal new
		databaseName: (soil ifNotNil: [ soil name ]);
		emit: aString
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
			self log: 'resident ', aResident name asString, ' failed to answer hasPendingWork: ', err messageText.
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
	merely logged -- the embedder needs the answer to decide"
	self residents do: [ :each |
		[ each startIn: aTransaction.
		each markStarted ]
			on: Error
			do: [ :err |
				each markFailed: err.
				self log: 'resident ', each name asString, ' failed to start: ', err messageText ] ]
]

{ #category : #running }
SoilResidentSupervisor >> startTickEvery: aDuration [
	"the interval is the embedder's business -- I only offer the tick. My own
	process, not a resident's: otherwise a hanging resident could not revive
	itself"
	self stopTick.
	tickProcess := [
		[ aDuration wait.
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
			do: [ :err | self log: 'resident ', each name asString, ' failed on requestStop: ', err messageText ] ].
	pending := self waitForReceipts: aDuration.
	pending do: [ :each |
		self log: 'resident ', each name asString, ' did not acknowledge the stop within ', aDuration asString, ', terminating'.
		[ each terminateProcesses ]
			on: Error
			do: [ :err | self log: 'resident ', each name asString, ' failed to terminate: ', err messageText ] ].
	self flushAll.
	^ pending
]

{ #category : #running }
SoilResidentSupervisor >> stopTick [
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
				do: [ :err | self log: 'resident ', each name asString, ' failed on tick: ', err messageText ] ] ]
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
