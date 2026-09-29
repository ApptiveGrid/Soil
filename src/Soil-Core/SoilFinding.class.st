"
Something a consistency check found, named so that it can be acted on: what it is (#kind), where it is, and the numbers that go with it. It prints itself for a log or a mail and answers a dictionary of plain values for anything that stores or sends it, like the metabase.

A finding is not a repair. SoilRepair asks each finding to be repaired and the finding picks the repair that fits it; one that has none says so.
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
		yourself
]

{ #category : #accessing }
SoilFinding >> description [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilFinding >> isRepairable [
	^ false
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
SoilFinding >> repairWith: aRepair [
	^ aRepair cannotRepair: self
]
