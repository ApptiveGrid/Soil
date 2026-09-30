"
Something a consistency check found, named so that it can be acted on: what it is (#kind), where it is, and the numbers that go with it. It prints itself for a log or a mail and answers a dictionary of plain values for anything that stores or sends it, like the metabase.

A finding is not a repair. It offers the repair actions that fit it (#repairActions), none when there is no repair for it, and at most one of them as its default. Which one is carried out is decided by a person; SoilRepairVisitor carries it out.
"
Class {
	#name : #SoilFinding,
	#superclass : #Object,
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilFinding >> asDictionary [
	^ Dictionary new
		at: #kind put: self kind;
		at: #description put: self description;
		at: #repairActions put: (self repairActions collect: [ :each | each asDictionary ]) asArray;
		yourself
]

{ #category : #repairing }
SoilFinding >> defaultRepairAction [
	"the action to take when all are repaired at once, nil where there is no one safe way"
	^ self repairActions
		detect: [ :each | each isDefault ]
		ifNone: [ nil ]
]

{ #category : #accessing }
SoilFinding >> description [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilFinding >> isRepairable [
	^ self repairActions notEmpty
]

{ #category : #accessing }
SoilFinding >> kind [
	^ self subclassResponsibility
]

{ #category : #printing }
SoilFinding >> printOn: aStream [
	aStream << self description
]

{ #category : #repairing }
SoilFinding >> repairActions [
	^ #()
]

{ #category : #accessing }
SoilFinding >> nodeIn: aSoilGraphTracker [
	"the node of the graph this finding is about, nil where it names none - how a
	view of the graph shows where something was found"
	^ nil
]
