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
		'window'
	],
	#category : #'Soil-Resident'
}

{ #category : #waiting }
SoilCoalescingRunStrategy >> awaitDue [
	super awaitDue.
	resident shouldStop ifFalse: [ resident waitForWorkUpTo: self window ]
]

{ #category : #accessing }
SoilCoalescingRunStrategy >> defaultWindow [
	^ 30 seconds
]

{ #category : #accessing }
SoilCoalescingRunStrategy >> window [
	^ window ifNil: [ window := self defaultWindow ]
]

{ #category : #accessing }
SoilCoalescingRunStrategy >> window: aDuration [
	window := aDuration
]
