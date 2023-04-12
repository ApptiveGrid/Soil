Class {
	#name : #SoilError,
	#superclass : #Error,
	#category : #'Soil-Core-Error'
}

{ #category : #testing }
SoilError class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilError
]
