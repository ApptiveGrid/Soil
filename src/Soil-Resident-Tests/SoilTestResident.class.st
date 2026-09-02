"
The dummy resident: one process, work units of a settable length, cancellation
checked between two units. It is what the base has to be provable against --
starts, works, acknowledges a requestStop, and answers questions about itself
without deciding anything.
"
Class {
	#name : #SoilTestResident,
	#superclass : #SoilResident,
	#instVars : [
		'process',
		'workDuration',
		'workSignal',
		'stepCount',
		'working',
		'pendingWork',
		'startCount',
		'tickCount'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #testing }
SoilTestResident >> basicHasPendingWork [
	^ pendingWork
]

{ #category : #testing }
SoilTestResident >> basicIsIdle [
	^ working not and: [ pendingWork not ]
]

{ #category : #testing }
SoilTestResident >> hasRunningProcess [
	^ process notNil and: [ process isTerminated not ]
]

{ #category : #initialization }
SoilTestResident >> initialize [
	super initialize.
	stepCount := 0.
	startCount := 0.
	tickCount := 0.
	working := false.
	pendingWork := false.
	workSignal := Semaphore new
]

{ #category : #testing }
SoilTestResident >> isWorking [
	^ working
]

{ #category : #accessing }
SoilTestResident >> name [
	^ #dummy
]

{ #category : #accessing }
SoilTestResident >> process [
	^ process
]

{ #category : #running }
SoilTestResident >> runLoop [
	[ self shouldStop ] whileFalse: [
		workSignal wait.
		self shouldStop ifFalse: [ self runStep ] ].
	self markStopped
]

{ #category : #running }
SoilTestResident >> runStep [
	working := true.
	[ workDuration wait.
	self withTransactionDo: [ :txn |
		| space |
		space := self workspaceIn: txn.
		space at: #steps put: (space at: #steps) + 1.
		txn commit ].
	stepCount := stepCount + 1.
	pendingWork := false ]
		ensure: [ working := false ]
]

{ #category : #accessing }
SoilTestResident >> startCount [
	^ startCount
]

{ #category : #running }
SoilTestResident >> startIn: aTransaction [
	"deliberately little: read the description, create the process. Anything that
	could fail on the environment would belong into the first work unit"
	startCount := startCount + 1.
	process := [ self runLoop ] forkNamed: 'soil test resident'
]

{ #category : #accessing }
SoilTestResident >> stepCount [
	^ stepCount
]

{ #category : #stopping }
SoilTestResident >> terminateProcesses [
	process ifNotNil: [ process terminate ].
	self markStopped
]

{ #category : #running }
SoilTestResident >> tick [
	"pull the process up again if it has terminated -- what the tick is for"
	tickCount := tickCount + 1.
	self hasRunningProcess ifFalse: [
		process := [ self runLoop ] forkNamed: 'soil test resident' ]
]

{ #category : #accessing }
SoilTestResident >> tickCount [
	^ tickCount
]

{ #category : #running }
SoilTestResident >> triggerWork [
	"a work signal from outside. The 'I have work' flag is set synchronously here,
	in the signalling process -- not first in the woken resident process, because
	between signal and scheduling is exactly the window in which a sweep strikes"
	pendingWork := true.
	workSignal signal
]

{ #category : #stopping }
SoilTestResident >> wakeUp [
	"my process is blocked on the work signal; without this it would never get to
	check the stop flag"
	workSignal signal
]

{ #category : #accessing }
SoilTestResident >> workDuration: aDuration [
	workDuration := aDuration
]
