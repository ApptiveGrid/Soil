"
A commit validation for tests of SoilTransaction>>#addCommitValidation:. It counts how often it runs and
signals an error when it is told to.
"
Class {
	#name : #SoilCommitValidationProbe,
	#superclass : #Object,
	#instVars : [
		'runs',
		'failing'
	],
	#category : #'Soil-Core-Tests-Transaction'
}

{ #category : #accessing }
SoilCommitValidationProbe >> beFailing [
	failing := true
]

{ #category : #initialization }
SoilCommitValidationProbe >> initialize [
	super initialize.
	runs := 0.
	failing := false
]

{ #category : #accessing }
SoilCommitValidationProbe >> runs [
	^ runs
]

{ #category : #validating }
SoilCommitValidationProbe >> validateIn: aTransaction [
	runs := runs + 1.
	failing ifTrue: [ SoilIndexHasConcurrentChange new indexId: 'probe'; signal ]
]
