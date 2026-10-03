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

{ #category : #checking }
SoilConsistencyTracker >> chainOf: aCluster in: aVisitor onFault: aBlock [
	"aCluster and every version before it, newest first, each without its payload. Where
	the chain cannot be followed on - a previous version that cannot be read, a version
	that does not come before the one after it, a position it has already been at - the
	fault is handed to aBlock with the position of the last record that is fine - the one
	whose link to its previous version cannot be followed - and what was found up to there
	is answered. Without the guard on positions a loop never ends"
	| segment current versions positions |
	segment := aVisitor soil objectRepository segmentAt: aCluster segment.
	versions := OrderedCollection with: aCluster.
	positions := Set with: aCluster position.
	current := aCluster.
	[ current hasPreviousVersion ] whileTrue: [ | position previous |
		position := current previousVersionPosition.
		(positions includes: position) ifTrue: [ 
			aBlock value: current position value: 'previous version leads back to position ', position printString.
			^ versions ].
		positions add: position.
		previous := [ (segment headAtPosition: position) objectId: aCluster objectId; yourself ]
			on: Error 
			do: [ :error | 
				aBlock value: current position value: 'previous version at position ', position printString, ' cannot be read: ', error messageText asString.
				^ versions ].
		previous version < current version ifFalse: [ 
			aBlock value: current position value: 'previous version ', previous version printString, ' at position ', position printString, ' does not come before version ', current version printString.
			^ versions ].
		versions add: previous.
		current := previous ].
	^ versions
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
