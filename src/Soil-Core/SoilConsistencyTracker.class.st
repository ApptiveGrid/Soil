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
SoilConsistencyTracker >> versionsOf: aCluster in: aVisitor onFault: aBlock do: eachBlock [
	"aCluster and every version before it, newest first, each without its payload, handed
	to eachBlock as the chain is followed and not kept: what is held is the set of
	positions the walk has been at, and nothing else.
	Where the chain cannot be followed on - a previous version that cannot be read, a
	version that does not come before the one after it, a position it has already been at
	- the fault is handed to aBlock with the position of the last record that is fine - the
	one whose link to its previous version cannot be followed - and the walk ends there.
	Without the guard on positions a loop never ends"
	| segment current positions |
	segment := aVisitor soil objectRepository segmentAt: aCluster segment.
	positions := Set with: aCluster position.
	current := aCluster.
	eachBlock value: current.
	[ current hasPreviousVersion ] whileTrue: [ | position previous |
		position := current previousVersionPosition.
		(positions includes: position) ifTrue: [ 
			^ aBlock value: current position value: 'previous version leads back to position ', position printString ].
		positions add: position.
		previous := [ (segment headAtPosition: position) objectId: aCluster objectId; yourself ]
			on: Error 
			do: [ :error | 
				^ aBlock value: current position value: 'previous version at position ', position printString, ' cannot be read: ', error messageText asString ].
		previous version < current version ifFalse: [ 
			^ aBlock value: current position value: 'previous version ', previous version printString, ' at position ', position printString, ' does not come before version ', current version printString ].
		eachBlock value: previous.
		current := previous ]
]

{ #category : #checking }
SoilConsistencyTracker >> chainOf: aCluster in: aVisitor onFault: aBlock [
	"aCluster and every version before it, newest first, each without its payload, as a
	collection. Holds the whole chain: an object that is written at every commit has a
	chain of a million records and the collection is more than a gigabyte - what
	#versionsOf:in:onFault:do: is for. This one stays for the checks that need the
	chain as a whole"
	| versions |
	versions := OrderedCollection new.
	self 
		versionsOf: aCluster 
		in: aVisitor 
		onFault: aBlock 
		do: [ :each | versions add: each ].
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
