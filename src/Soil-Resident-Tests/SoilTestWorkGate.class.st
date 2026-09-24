"
A work gate that says who has arrived. What an embedder hands a supervisor is a
Mutex of its own; I am one plus a semaphore that every caller signals before it
waits, so a test can tell that a resident has got as far as the gate instead of
guessing with a sleep.

The embedder's side of the gate can be taken over for one hold as well:
#whenNextHeld: runs a block inside the next critical section, before whatever
the holder brought -- which is how a test puts a resident at the gate while the
embedder's own code holds it.
"
Class {
	#name : #SoilTestWorkGate,
	#superclass : #Object,
	#instVars : [
		'mutex',
		'arrivals',
		'nextHold'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #accessing }
SoilTestWorkGate >> arrivals [
	^ arrivals
]

{ #category : #'mutual exclusion' }
SoilTestWorkGate >> critical: aBlock [
	arrivals signal.
	^ mutex critical: [
		| hold |
		hold := nextHold.
		nextHold := nil.
		hold ifNotNil: [ hold value ].
		aBlock value ]
]

{ #category : #initialization }
SoilTestWorkGate >> initialize [
	super initialize.
	mutex := Mutex new.
	arrivals := Semaphore new
]

{ #category : #accessing }
SoilTestWorkGate >> whenNextHeld: aBlock [
	nextHold := aBlock
]
