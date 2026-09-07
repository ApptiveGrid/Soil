"
Wait for a signal, and then wait a little longer on purpose: everything arriving
during that window is absorbed into the same step instead of causing one of its
own.

For work that is triggered far more often than it needs to be done. A limit that
is asked about and used once per flow node would otherwise be one commit per
node; with a window it is one commit per burst.

The window is waited out on the resident's work signal rather than on the clock,
so that a stop cuts it short. Nothing is lost by cutting it: the resident's
pending flag is still up -- it is cleared only when a step begins -- and his
#flushOnStop writes what the window was still holding.
"
Class {
	#name : #SoilCoalescingRunStrategy,
	#superclass : #SoilSignalRunStrategy,
	#instVars : [
		'window',
		'deadline'
	],
	#category : #'Soil-Resident'
}

{ #category : #waiting }
SoilCoalescingRunStrategy >> awaitDue [
	"the window is waited out against a deadline, not against a single wait on the
	work signal. Two things would otherwise cut it short, and both are the very
	work it exists to collect: a signal still standing when we get here -- super
	returns at once whenever work was already pending, leaving the signal up -- and
	a change arriving while we wait. Only a stop may end the window early, and it
	still does: the flag is checked every turn, and #requestStop wakes us to see it."
	super awaitDue.
	deadline := DateAndTime now + self window.
	[ [ resident shouldStop not and: [ DateAndTime now < deadline ] ] whileTrue: [
		resident waitForWorkUpTo: deadline - DateAndTime now ] ]
		ensure: [ deadline := nil ]
]

{ #category : #accessing }
SoilCoalescingRunStrategy >> defaultWindow [
	^ 30 seconds
]

{ #category : #testing }
SoilCoalescingRunStrategy >> isInWindow [
	"am I inside the collecting window right now? The one state of mine worth
	asking about from outside: a caller that needs a resident to have really
	reached its window cannot read that off the resident, whose #isWorking covers
	the step and deliberately not the wait before it."
	^ deadline notNil
]

{ #category : #accessing }
SoilCoalescingRunStrategy >> window [
	^ window ifNil: [ window := self defaultWindow ]
]

{ #category : #accessing }
SoilCoalescingRunStrategy >> window: aDuration [
	window := aDuration
]
