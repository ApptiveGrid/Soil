"
Description of a resident that throws wherever it is asked something. It exists
so the error isolation can be proved on every path the supervisor walks: tick,
the two answers, and the stop flush.
"
Class {
	#name : #SoilTestThrowingResidentDescription,
	#superclass : #SoilResidentDescription,
	#category : #'Soil-Resident-Tests'
}

{ #category : #'instance creation' }
SoilTestThrowingResidentDescription >> instanceClass [
	^ SoilTestThrowingResident
]

{ #category : #accessing }
SoilTestThrowingResidentDescription >> name [
	^ #throwing
]
