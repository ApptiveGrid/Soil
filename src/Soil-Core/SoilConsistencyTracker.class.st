"
A tracker that checks what it is shown and collects what fails as findings (SoilFinding) - it reports, it does not repair. Checking and repairing are two calls; each finding offers its repair actions, and SoilRepairVisitor carries out the ones a person chose.

Two levels, one subclass each: SoilDatabaseConsistencyTracker checks the structure on disk and needs no transaction, SoilApplicationConsistencyTracker checks that the stored objects fit the classes of this image and needs one.
"
Class {
	#name : #SoilConsistencyTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'findings'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilConsistencyTracker >> check: anObject using: aBlock [
	"a check that fails in a way no finding names is kept as one all the same"
	aBlock 
		on: Error 
		do: [ :error | self report: (SoilUnexpectedFinding subject: anObject error: error) ]
]

{ #category : #accessing }
SoilConsistencyTracker >> findings [
	^ findings
]

{ #category : #initialization }
SoilConsistencyTracker >> initialize [ 
	super initialize.
	findings := OrderedCollection new
]

{ #category : #checking }
SoilConsistencyTracker >> report: aSoilFinding [
	findings add: aSoilFinding
]
