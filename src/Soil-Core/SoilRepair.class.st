"
Repairs what a consistency check found, finding by finding: each finding picks the repair that fits it (#repairWith:), one without a repair is kept as not repairable. It writes, so it only runs where writing is allowed, and it is started by a person.

The first repair it knows is an index size that drifted: SoilIndex>>recomputeSize on the index as its segment holds it, never on the copy-on-write layer a transaction sees, whose pages would never reach the disk; the checkpoint at the end writes the header pages.
"
Class {
	#name : #SoilRepair,
	#superclass : #Object,
	#instVars : [
		'soil',
		'repaired',
		'notRepairable'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilRepair class >> on: aSoil [
	^ self new
		soil: aSoil;
		yourself
]

{ #category : #repairing }
SoilRepair >> cannotRepair: aFinding [
	notRepairable add: aFinding
]

{ #category : #initialization }
SoilRepair >> initialize [
	super initialize.
	repaired := OrderedCollection new.
	notRepairable := OrderedCollection new
]

{ #category : #accessing }
SoilRepair >> notRepairable [
	^ notRepairable
]

{ #category : #repairing }
SoilRepair >> repair: aSoilConsistencyReport [
	^ self repairFindings: aSoilConsistencyReport findings
]

{ #category : #repairing }
SoilRepair >> repairFindings: aCollectionOfFindings [
	aCollectionOfFindings do: [ :each | each repairWith: self ].
	repaired ifNotEmpty: [ soil checkpoint ]
]

{ #category : #repairing }
SoilRepair >> repairIndexSizeDrift: aFinding [
	(aFinding indexIn: soil) recomputeSize.
	repaired add: aFinding
]

{ #category : #accessing }
SoilRepair >> repaired [
	^ repaired
]

{ #category : #accessing }
SoilRepair >> soil: aSoil [
	soil := aSoil
]
