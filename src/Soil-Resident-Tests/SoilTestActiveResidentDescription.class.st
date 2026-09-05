"
Description of the dummy active resident. It carries the cadence as a Symbol and
its two durations, because those are what a test varies -- and all three survive
being written, which a class or a block would not.
"
Class {
	#name : #SoilTestActiveResidentDescription,
	#superclass : #SoilResidentDescription,
	#instVars : [
		'cadence',
		'window',
		'interval'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #accessing }
SoilTestActiveResidentDescription >> cadence [
	^ cadence ifNil: [ #signal ]
]

{ #category : #accessing }
SoilTestActiveResidentDescription >> cadence: aSymbol [
	cadence := aSymbol
]

{ #category : #initialization }
SoilTestActiveResidentDescription >> initializeFrom: aTransaction [
	workspace := SoilPersistentDictionary new.
	aTransaction makeRoot: workspace.
	workspace at: #steps put: 0
]

{ #category : #'instance creation' }
SoilTestActiveResidentDescription >> instanceClass [
	^ SoilTestActiveResident
]

{ #category : #accessing }
SoilTestActiveResidentDescription >> interval [
	^ interval
]

{ #category : #accessing }
SoilTestActiveResidentDescription >> interval: aDuration [
	interval := aDuration
]

{ #category : #accessing }
SoilTestActiveResidentDescription >> name [
	^ #active
]

{ #category : #'instance creation' }
SoilTestActiveResidentDescription >> newInstanceIn: aTransaction [
	^ (super newInstanceIn: aTransaction)
		cadence: self cadence;
		window: self window;
		interval: self interval;
		yourself
]

{ #category : #accessing }
SoilTestActiveResidentDescription >> window [
	^ window
]

{ #category : #accessing }
SoilTestActiveResidentDescription >> window: aDuration [
	window := aDuration
]
