"
A tracker that checks what it is shown and collects what fails - it reports, it does not repair. Checking and repairing are two calls; the repair is a process of its own that takes what was collected here.

Two levels, one subclass each: SoilDatabaseConsistencyTracker checks the structure on disk and needs no transaction, SoilApplicationConsistencyTracker checks that the stored objects fit the classes of this image and needs one.
"
Class {
	#name : #SoilConsistencyTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'errors'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilConsistencyTracker >> check: anObject using: aBlock [
	aBlock 
		on: Error 
		do: [ :error | errors at: anObject put: error ]
]

{ #category : #accessing }
SoilConsistencyTracker >> errors [
	^ errors
]

{ #category : #initialization }
SoilConsistencyTracker >> initialize [ 
	super initialize.
	errors := Dictionary new
]
