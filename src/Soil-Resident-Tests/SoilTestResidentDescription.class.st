"
Description of the dummy resident used to prove the base: an active resident
whose work unit is deliberately slow, so the window between 'is it idle' and
'it starts working' becomes observable.
"
Class {
	#name : #SoilTestResidentDescription,
	#superclass : #SoilResidentDescription,
	#instVars : [
		'workDuration'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #initialization }
SoilTestResidentDescription >> initializeFrom: aTransaction [
	workspace := SoilPersistentDictionary new.
	aTransaction makeRoot: workspace.
	workspace at: #steps put: 0
]

{ #category : #'instance creation' }
SoilTestResidentDescription >> instanceClass [
	^ SoilTestResident
]

{ #category : #accessing }
SoilTestResidentDescription >> name [
	^ #dummy
]

{ #category : #'instance creation' }
SoilTestResidentDescription >> newInstanceIn: aTransaction [
	^ (super newInstanceIn: aTransaction)
		workDuration: self workDuration;
		yourself
]

{ #category : #accessing }
SoilTestResidentDescription >> workDuration [
	^ workDuration ifNil: [ 50 milliSeconds ]
]

{ #category : #accessing }
SoilTestResidentDescription >> workDuration: aDuration [
	workDuration := aDuration
]
