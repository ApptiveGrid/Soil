Class {
	#name : #SoilTestHangingResident,
	#superclass : #SoilResident,
	#instVars : [
		'process',
		'tickCount'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #testing }
SoilTestHangingResident >> hasRunningProcess [
	^ process notNil and: [ process isTerminated not ]
]

{ #category : #initialization }
SoilTestHangingResident >> initialize [
	super initialize.
	tickCount := 0
]

{ #category : #accessing }
SoilTestHangingResident >> name [
	^ #hanging
]

{ #category : #accessing }
SoilTestHangingResident >> process [
	^ process
]

{ #category : #running }
SoilTestHangingResident >> startIn: aTransaction [
	"deliberately never looks at the stop flag"
	process := [ [ 1 second wait ] repeat ] forkNamed: 'soil test hanging resident'
]

{ #category : #stopping }
SoilTestHangingResident >> terminateProcesses [
	process ifNotNil: [ process terminate ].
	self markStopped
]
{ #category : #running }
SoilTestHangingResident >> tick [
	tickCount := tickCount + 1
]

{ #category : #accessing }
SoilTestHangingResident >> tickCount [
	^ tickCount
]

