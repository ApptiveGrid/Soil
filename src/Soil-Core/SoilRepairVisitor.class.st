"
Carries out the repair actions a person chose (SoilRepairAction), at the places they name and nowhere else - no walk over the database, what a finding names is already where to go. It writes, so it only runs where writing is allowed, and it is started by a person.

An action that fails is kept with its error and the others go on; the checkpoint at the end writes what was repaired. Whether a finding is gone is for the next check to say, not for this visitor.
"
Class {
	#name : #SoilRepairVisitor,
	#superclass : #SoilBasicVisitor,
	#instVars : [
		'soil',
		'repaired',
		'failed'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #'instance creation' }
SoilRepairVisitor class >> on: aSoil [
	^ self new
		soil: aSoil;
		yourself
]

{ #category : #accessing }
SoilRepairVisitor >> failed [
	"the actions that failed, each with the text of its error"
	^ failed
]

{ #category : #initialization }
SoilRepairVisitor >> initialize [
	super initialize.
	repaired := OrderedCollection new.
	failed := OrderedCollection new
]

{ #category : #api }
SoilRepairVisitor >> repair: aCollectionOfRepairActions [
	aCollectionOfRepairActions do: [ :each |
		[ self visit: each.
		  repaired add: each ]
			on: Error
			do: [ :error | failed add: each -> error messageText asString ] ].
	repaired ifNotEmpty: [ soil checkpoint ]
]

{ #category : #accessing }
SoilRepairVisitor >> repaired [
	^ repaired
]

{ #category : #accessing }
SoilRepairVisitor >> soil: aSoil [
	soil := aSoil
]

{ #category : #visiting }
SoilRepairVisitor >> visitRecomputeIndexSize: aRepairAction [
	"on the index as its segment holds it, never on the copy-on-write layer a
	transaction sees, whose pages would never reach the disk"
	(aRepairAction indexIn: soil) recomputeSize
]
