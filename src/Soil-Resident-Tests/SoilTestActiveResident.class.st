"
The dummy active resident: it counts its steps and can be told to leave work
behind, to throw, and which cadence to run on. Everything it does is in memory,
so that a drain test is not a test of transaction speed.

Which strategy it uses arrives as a Symbol rather than as a class, because the
description that carries the setting is a persisted cluster root -- a class or a
block in there would have to be serialized.
"
Class {
	#name : #SoilTestActiveResident,
	#superclass : #SoilActiveResident,
	#instVars : [
		'cadence',
		'window',
		'interval',
		'stepCount',
		'prepareCount',
		'workToLeave',
		'throwOnStep',
		'stepSignal'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #accessing }
SoilTestActiveResident >> cadence: aSymbol [
	cadence := aSymbol
]

{ #category : #initialization }
SoilTestActiveResident >> initialize [
	super initialize.
	stepCount := 0.
	prepareCount := 0.
	workToLeave := 0.
	throwOnStep := false.
	stepSignal := Semaphore new
]

{ #category : #accessing }
SoilTestActiveResident >> interval [
	^ interval ifNil: [ 50 milliSeconds ]
]

{ #category : #accessing }
SoilTestActiveResident >> interval: aDuration [
	interval := aDuration
]

{ #category : #accessing }
SoilTestActiveResident >> name [
	^ #active
]

{ #category : #'instance creation' }
SoilTestActiveResident >> newRunStrategy [
	| strat |
	strat := super newRunStrategy.
	cadence = #coalescing ifTrue: [ strat window: self window ].
	cadence = #interval ifTrue: [ strat interval: self interval ].
	^ strat
]

{ #category : #accessing }
SoilTestActiveResident >> prepareCount [
	^ prepareCount
]

{ #category : #running }
SoilTestActiveResident >> prepareIn: aTransaction [
	prepareCount := prepareCount + 1
]

{ #category : #running }
SoilTestActiveResident >> runStep [
	"the signal is given in the ensure, so that a throwing step is observable too"
	[ stepCount := stepCount + 1.
	workToLeave > 0 ifTrue: [
		workToLeave := workToLeave - 1.
		self noteWork ].
	throwOnStep ifTrue: [ Error signal: 'the step was told to throw' ] ]
		ensure: [ stepSignal signal ]
]

{ #category : #accessing }
SoilTestActiveResident >> runStrategyClass [
	cadence = #coalescing ifTrue: [ ^ SoilCoalescingRunStrategy ].
	cadence = #interval ifTrue: [ ^ SoilIntervalRunStrategy ].
	^ SoilSignalRunStrategy
]

{ #category : #accessing }
SoilTestActiveResident >> stepCount [
	^ stepCount
]

{ #category : #accessing }
SoilTestActiveResident >> throwOnStep: aBoolean [
	throwOnStep := aBoolean
]

{ #category : #waiting }
SoilTestActiveResident >> waitForStepWithin: aDuration [
	"answers whether a step finished in time, so that tests synchronise on the
	work rather than on a sleep long enough to be safe"
	^ (stepSignal waitTimeoutMilliseconds: aDuration asMilliSeconds) not
]

{ #category : #accessing }
SoilTestActiveResident >> window [
	^ window ifNil: [ 50 milliSeconds ]
]

{ #category : #accessing }
SoilTestActiveResident >> window: aDuration [
	window := aDuration
]

{ #category : #accessing }
SoilTestActiveResident >> workToLeave: anInteger [
	"how many of the coming steps say afterwards that there is still work"
	workToLeave := anInteger
]
