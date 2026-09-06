"
Run once per interval, by the clock. For work whose moment nobody announces --
fetching from a foreign service, for instance.

The waiting happens on the resident's work signal with a timeout, not on the
clock alone, and that is the point rather than a detail. Waited out on the clock,
a stop request would have to sit through the whole interval before the loop even
looks at the flag, and the embedder's stop timeout would then have to exceed the
longest interval in the system. The old AGIntervalRunStrategy waits with
(nextRun - now) wait and has exactly that problem; it was never noticed because
that world stopped its residents by terminating the process.

The interval counts from the start of a step, not from its end: a step that
takes longer than the interval is then due again immediately rather than pushing
the schedule ahead of itself.
"
Class {
	#name : #SoilIntervalRunStrategy,
	#superclass : #SoilResidentRunStrategy,
	#instVars : [
		'interval',
		'lastRun'
	],
	#category : #'Soil-Resident'
}

{ #category : #waiting }
SoilIntervalRunStrategy >> awaitDue [
	[ self isDue ] whileFalse: [
		resident waitForWorkUpTo: self remaining.
		resident shouldStop ifTrue: [ ^ self ] ].
	lastRun := DateAndTime now
]

{ #category : #accessing }
SoilIntervalRunStrategy >> defaultInterval [
	^ 1 minute
]

{ #category : #accessing }
SoilIntervalRunStrategy >> interval [
	^ interval ifNil: [ interval := self defaultInterval ]
]

{ #category : #accessing }
SoilIntervalRunStrategy >> interval: aDuration [
	interval := aDuration
]

{ #category : #testing }
SoilIntervalRunStrategy >> isDue [
	"never run yet counts as due: a resident starts by doing its work once, and
	waiting out a first interval would leave a freshly opened database stale for
	no reason"
	^ lastRun isNil or: [ DateAndTime now >= self nextRun ]
]

{ #category : #accessing }
SoilIntervalRunStrategy >> lastRun [
	^ lastRun
]

{ #category : #accessing }
SoilIntervalRunStrategy >> lastRun: aDateAndTime [
	"so that a resident whose description remembers when it last ran does not
	repeat the work after every restart"
	lastRun := aDateAndTime
]

{ #category : #accessing }
SoilIntervalRunStrategy >> nextRun [
	^ lastRun + self interval
]

{ #category : #accessing }
SoilIntervalRunStrategy >> remaining [
	^ self nextRun - DateAndTime now
]
