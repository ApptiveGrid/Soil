"
Description of a passive resident: no process, consulted all the time, writes
only periodically -- and on stop it has to write what it collected instead of
discarding it. The reference case for the stop flush.
"
Class {
	#name : #SoilTestPassiveResidentDescription,
	#superclass : #SoilResidentDescription,
	#category : #'Soil-Resident-Tests'
}

{ #category : #initialization }
SoilTestPassiveResidentDescription >> initializeFrom: aTransaction [
	workspace := SoilPersistentDictionary new.
	aTransaction makeRoot: workspace.
	workspace at: #flushed put: 0
]

{ #category : #'instance creation' }
SoilTestPassiveResidentDescription >> instanceClass [
	^ SoilTestPassiveResident
]

{ #category : #accessing }
SoilTestPassiveResidentDescription >> name [
	^ #passive
]
