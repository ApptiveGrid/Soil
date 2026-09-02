Class {
	#name : #SoilResidentAlreadyPresent,
	#superclass : #SoilResidentError,
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentAlreadyPresent >> messageText [
	^ 'a resident named ', name asString, ' is already present in this database'
]
