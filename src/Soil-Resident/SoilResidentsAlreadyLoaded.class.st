"
Signalled when a supervisor is asked to load its residents a second time. A
second load would build a second set of instances while the first set is
started and holding processes, and named access would then reach only the
newcomers.
"
Class {
	#name : #SoilResidentsAlreadyLoaded,
	#superclass : #SoilError,
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentsAlreadyLoaded >> messageText [
	^ 'the residents of this database are already loaded'
]
