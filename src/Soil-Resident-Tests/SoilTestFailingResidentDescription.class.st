"
Description of a resident that throws on start. It proves two things at once:
the error is left behind visibly rather than merely logged, and the other
residents are untouched by it.
"
Class {
	#name : #SoilTestFailingResidentDescription,
	#superclass : #SoilResidentDescription,
	#category : #'Soil-Resident-Tests'
}

{ #category : #'instance creation' }
SoilTestFailingResidentDescription >> instanceClass [
	^ SoilTestFailingResident
]

{ #category : #accessing }
SoilTestFailingResidentDescription >> name [
	^ #failing
]
