"
Signalled when a resident is asked for by a name no resident carries. This is
what named access answers with instead of nil: code that wants a resident wants
it, and a nil would surface as a doesNotUnderstand somewhere further away.
"
Class {
	#name : #SoilResidentNotFound,
	#superclass : #SoilResidentError,
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentNotFound >> messageText [
	^ 'there is no resident named ', name asString, ' in this database'
]
