"
Common superclass for all Soil errors
"
Class {
	#name : #SOError,
	#superclass : #Error,
	#category : #'Soil-Core-Error'
}

{ #category : #testing }
SOError class >> isAbstract [
	<ignoreForCoverage>
	^ self == SOError
]
