Class {
	#name : #SoilIncompatibleDatabaseFormat,
	#superclass : #SoilError,
	#category : #'Soil-Core-Error'
}

{ #category : #'private - testing' }
SoilIncompatibleDatabaseFormat >> isResumable [ 
	^ true 
]
