Class {
	#name : #SoilResidentNotFound,
	#superclass : #SoilResidentError,
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentNotFound >> messageText [
	^ 'there is no resident named ', name asString, ' in this database'
]
