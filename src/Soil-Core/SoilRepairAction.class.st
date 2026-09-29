"
One way to repair what a finding names, at the place it names. A finding offers the actions that fit it (SoilFinding>>repairActions), a person chooses, and SoilRepairVisitor carries out the chosen ones.

An action is written as a dictionary of plain values and made again from one (#fromDictionary:), so a script run by hand and a route that takes the choice as data start from the same form. Only the kinds of action defined here can be made from a dictionary; any other name is refused.

An action may be the default of its finding, and only where there is exactly one safe way. Repairing all takes the defaults; a finding without one is decided on its own.
"
Class {
	#name : #SoilRepairAction,
	#superclass : #Object,
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilRepairAction class >> actionName [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SoilRepairAction class >> fromDictionary: aDictionary [
	| wanted |
	wanted := (aDictionary at: #action ifAbsent: [ nil ]) ifNotNil: [ :each | each asSymbol ].
	^ (self allSubclasses
		detect: [ :each | each isAbstract not and: [ each actionName = wanted ] ]
		ifNone: [ ^ SoilUnknownRepairAction signal: 'no repair action named ', wanted printString ])
			newFromDictionary: aDictionary
]

{ #category : #testing }
SoilRepairAction class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilRepairAction
]

{ #category : #'instance creation' }
SoilRepairAction class >> newFromDictionary: aDictionary [
	^ self subclassResponsibility
]

{ #category : #visiting }
SoilRepairAction >> acceptSoil: aSoilVisitor [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilRepairAction >> actionName [
	^ self class actionName
]

{ #category : #accessing }
SoilRepairAction >> asDictionary [
	^ Dictionary new
		at: #action put: self actionName;
		at: #description put: self description;
		at: #default put: self isDefault;
		yourself
]

{ #category : #accessing }
SoilRepairAction >> description [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilRepairAction >> isDefault [
	^ false
]

{ #category : #printing }
SoilRepairAction >> printOn: aStream [
	aStream << self description
]
