"
Description of a resident that ignores the stop flag. It is what the timeout in
the stop handshake exists for -- the image has to be able to quit even so.
"
Class {
	#name : #SoilTestHangingResidentDescription,
	#superclass : #SoilResidentDescription,
	#category : #'Soil-Resident-Tests'
}

{ #category : #'instance creation' }
SoilTestHangingResidentDescription >> instanceClass [
	^ SoilTestHangingResident
]

{ #category : #accessing }
SoilTestHangingResidentDescription >> name [
	^ #hanging
]
