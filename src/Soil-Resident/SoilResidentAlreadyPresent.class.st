"
Signalled when a description is added under a name the registry already holds.
The registry is a map rather than a list precisely so this cannot pass
unnoticed -- two residents under one name would make named access pick one of
them arbitrarily.
"
Class {
	#name : #SoilResidentAlreadyPresent,
	#superclass : #SoilResidentError,
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentAlreadyPresent >> messageText [
	^ 'a resident named ', name asString, ' is already present in this database'
]
